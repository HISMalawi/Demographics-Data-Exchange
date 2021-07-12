require 'active_record'
require 'activerecord-import'

namespace :migration do
  desc "Data Migration from dde3 to dd4"
  task data_migration: :environment do
      require 'benchmark'
      require 'zlib'
      require "people_matching_service/bantu_soundex"

      config   = Rails.configuration.database_configuration
      @username = config[Rails.env]["username"]
      @password = config[Rails.env]["password"]
      @database_main = config[Rails.env]["database"]
      @batch_size = 200_000


      def init_insert
        sql = "INSERT INTO `location_npids` (`location_id`, `npid`, `assigned`, `created_at`, `updated_at`) VALUES "
      end

      def load_file(db, file)
        puts "loading #{file} into #{db}"
        infile = open(file)
        gz = Zlib::GzipReader.new(infile)

        statements = gz.split(/;$/)
        statements.pop

        db_con = ActiveRecord::Base.establish_connection({:username => @username,
                                                          :password => @password,
                                                          :database => db})

        ActiveRecord::Base.transaction do
          statements.each do | statement |
            db_con.connection.execute(statement)
          end
        end
      end

      def load_dumps
        files = Dir.glob("#{Rails.root}/storage/*.gz")


        Parallel.each_with_index(files) do | file, i |

         sql = "CREATE DATABASE IF NOT EXISTS npid_update#{i};"

          ActiveRecord::Base.connection.execute(sql)
          puts "Loading #{file} into npid_update#{i}"
         `pv #{file} | gunzip | mysql -u#{@username} -p#{@password} npid_update#{i}`
        end
      end

      def format_person(person)
        person = {
          first_name:             person['given_name'],
          last_name:              person['family_name'],
          middle_name:            person['middle_name'],
          birthdate:              (person['birthdate'].to_date.strftime('%Y-%m-%d') rescue 'NULL'),
          birthdate_estimated:    person['birthdate_estimated'],
          gender:                 person['gender'][0].to_s.upcase,
          ancestry_district:      person['ancestry_district'],
          ancestry_ta:            person['ancestry_ta'],
          ancestry_village:       person['ancestry_village'],
          home_district:          person['home_district'],
          home_ta:                person['home_ta'],
          home_village:           person['home_village'],
          npid:                   person['npid'],
          person_uuid:            person['couchdb_person_id'],
          date_registered:        (person['created_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S') rescue '1900-01-01 00:00:00'),
          last_edited:            (person['updated_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S') rescue '1900-01-01 00:00:00'),
          location_created_at:    person['location_created_at'],
          location_updated_at:    person['location_created_at'],
          creator:                person['creator'],
          voided:                 person['voided'],
          voided_by:              (person['voided_by'] || 'NULL'),
          date_voided:            (person['date_voided'].to_datetime.strftime('%Y-%m-%d %H:%M:%S') rescue 'NULL'),
          void_reason:            person['void_reason'],
          first_name_soundex:     person['given_name'].soundex,
          last_name_soundex:      person['family_name'].soundex
        }
      end

      def import_non_duplicate_records(database)
        min = 0
        max = @batch_size.dup
        max_id = ActiveRecord::Base.connection.select_all("SELECT max(person_id) max_id FROM #{database}.people").first['max_id'].to_i

        n = ((max_id / @batch_size) + 1).to_i

        puts "Processing #{database} #{n} batches of #{@batch_size} each"

        select_people = []
        (1..n).each do |num|
          select_people << "SELECT pple.*, attr.* FROM #{database}.people pple LEFT JOIN
                            (
                            SELECT anc.person_id, anc.ancestry_district, anc_ta.ancestry_ta, anc_village.ancestry_village,
                            hme_district.home_district,
                            home_ta.home_ta,
                            hme_vllg.home_village
                            FROM
                            (SELECT pa.person_id, pa.value ancestry_district FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 4 and pa.voided = 0) anc
                            JOIN
                            (SELECT pa.person_id, pa.value ancestry_ta FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 5 and pa.voided = 0) anc_ta
                            ON anc.person_id = anc_ta.person_id
                            JOIN
                            (SELECT pa.person_id, pa.value ancestry_village FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 6 and pa.voided = 0) anc_village
                            ON anc.person_id = anc_village.person_id
                            JOIN
                            (SELECT pa.person_id, pa.value home_district FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 1 and pa.voided = 0) hme_district
                            ON anc.person_id = hme_district.person_id
                            JOIN
                            (SELECT pa.person_id, pa.value home_ta FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 2 and pa.voided = 0) home_ta
                            ON anc.person_id = home_ta.person_id
                            JOIN
                            (SELECT pa.person_id, pa.value home_village FROM #{database}.person_attributes pa
                            WHERE pa.person_attribute_type_id = 3 and pa.voided = 0) hme_vllg
                            ON anc.person_id = hme_vllg.person_id) attr
                            ON pple.person_id = attr.person_id
                            WHERE length(pple.npid) > 0
                            AND given_name is not null
                            AND family_name is not null
                            AND pple.person_id > #{min}
                            AND pple.person_id <= #{max}"
           min += @batch_size.dup
           max += @batch_size.dup
        end
        select_people.each do |query|
          batch = ActiveRecord::Base.connection.select_all <<-SQL
             #{query}
           SQL
          records = Parallel.map(batch) do | person|
             format_person(person)
          end

          ActiveRecord::Base.transaction do
            PersonDetail.import(records, validate: false, on_duplicate_key_ignore: true)
          end
          puts records.size
        end
      end

      def main
          #load_dumps

          site_databases = ActiveRecord::Base.connection.execute <<~SQL
            SHOW DATABASES LIKE 'npid_update%';
          SQL

          # site_databases.each do | database |
          #   update_npids = "UPDATE #{@database_main}.npids SET assigned = 1 WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids);"

          #   ActiveRecord::Base.connection.execute(update_npids)

          #   unavailable_npids = "SELECT #{LocationNpid.column_names[1..7].join(', ')} FROM #{database[0]}.location_npids WHERE npid NOT IN (SELECT npid FROM #{@database_main}.location_npids) AND length(npid) <> 0;"

          #   un_npids = ActiveRecord::Base.connection.execute(unavailable_npids)

          #   sql_batch_insert = init_insert

          #   count = un_npids.count

          #   un_npids.each_with_index do |row, n|
          #       row.each_with_index do | value, i |
          #        sql_batch_insert << "(\"#{value}\"," if i == 0
          #        sql_batch_insert << "\"#{value}\"," if i < 5 && i > 0
          #        sql_batch_insert << ("\"#{value.to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"," rescue "\"#{row[6].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"," rescue '"1900-01-01 00:00:00",') if i == 5
          #        sql_batch_insert << ("\"#{value.to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\")," rescue "\"#{row[5].strftime.to_datetime('%Y-%m-%d %H:%M:%S')}\")," rescue '"1900-01-01 00:00:00"),') if i == 6
          #       end
          #     if n > 0
          #       if (n + 1) % @batch_size == 0 || count == n + 1
          #         ActiveRecord::Base.connection.execute(sql_batch_insert.chomp!(','))
          #         sql_batch_insert = init_insert
          #       end
          #     end
          #   end
          #   puts "updating location_npids assigned state for #{database[0]}"

          #   update_location_npid_state = "UPDATE #{@database_main}.location_npids SET assigned = 1 WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids WHERE assigned = 1);"

          #   ActiveRecord::Base.connection.execute(update_location_npid_state)
          # end
          #Migrate data
          site_databases.each_with_index do |database, i|
            puts "Migrating database #{i+1} of #{site_databases.count}"
            output = ActiveRecord::Base.connection.execute <<~SQL
              INSERT
                IGNORE
              INTO
                #{@database_main}.person_details ( first_name,
                last_name,
                middle_name,
                birthdate,
                birthdate_estimated,
                gender,
                ancestry_district,
                ancestry_ta,
                ancestry_village,
                home_district,
                home_ta,
                home_village,
                npid,
                person_uuid,
                date_registered,
                last_edited,
                location_created_at,
                location_updated_at,
                created_at,
                updated_at,
                creator,
                voided,
                date_voided,
                void_reason )
              SELECT
                given_name,
                family_name,
                middle_name,
                birthdate,
                birthdate_estimated,
                LEFT(gender,
                1),
                attr.*,
                npid,
                couchdb_person_id created_at,
                updated_at,
                location_created_at,
                location_created_at,
                created_at,
                updated_at,
                creator,
                voided,
                date_voided,
                void_reason
              FROM
                #{database[0]}.people pple
              LEFT JOIN (
                SELECT
                  anc.person_id,
                  anc.ancestry_district,
                  anc_ta.ancestry_ta,
                  anc_village.ancestry_village,
                  hme_district.home_district,
                  home_ta.home_ta,
                  hme_vllg.home_village
                FROM
                  (
                  SELECT
                    pa.person_id,
                    pa.value ancestry_district
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 4
                    and pa.voided = 0) anc
                JOIN (
                  SELECT
                    pa.person_id,
                    pa.value ancestry_ta
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 5
                    and pa.voided = 0) anc_ta ON
                  anc.person_id = anc_ta.person_id
                JOIN (
                  SELECT
                    pa.person_id,
                    pa.value ancestry_village
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 6
                    and pa.voided = 0) anc_village ON
                  anc.person_id = anc_village.person_id
                JOIN (
                  SELECT
                    pa.person_id,
                    pa.value home_district
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 1
                    and pa.voided = 0) hme_district ON
                  anc.person_id = hme_district.person_id
                JOIN (
                  SELECT
                    pa.person_id,
                    pa.value home_ta
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 2
                    and pa.voided = 0) home_ta ON
                  anc.person_id = home_ta.person_id
                JOIN (
                  SELECT
                    pa.person_id,
                    pa.value home_village
                  FROM
                    #{database[0]}.person_attributes pa
                  WHERE
                    pa.person_attribute_type_id = 3
                    and pa.voided = 0) hme_vllg ON
                  anc.person_id = hme_vllg.person_id) attr ON
                pple.person_id = attr.person_id
              WHERE
                length(npid) > 0
                AND (given_name is not null
                  OR LENGTH(given_name) > 1)
                AND (family_name is not null
                  OR LENGTH(family_name) > 1);
            SQL
            puts output
            exit
          end
            # sql = "DROP database #{database[0]};"
            # puts "Cleaning #{database[0]}"
            # ActiveRecord::Base.connection.execute(sql)
      end

      main

        end

end
