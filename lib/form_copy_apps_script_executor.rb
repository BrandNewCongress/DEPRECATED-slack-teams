require 'google/apis/script_v1'
require 'dotenv'
Dotenv.load

class FormCopyAppsScriptExecutor
  attr_accessor :client

  def copy_form(city, spreadsheet_key)

    request = Google::Apis::ScriptV1::ExecutionRequest.new(
      function: 'copyFormAndUpdateProperties',
      parameters: [
        ENV['ORIGINAL_GOOGLE_FORM_ID'] || '',
        "#{city.capitalize} BNC Tour Volunteer To-Do List",
        spreadsheet_key
      ],
      devMode: false
    )

    begin
      resp = client.run_script(ENV['FORM_COPY_APPS_SCRIPT_ID'], request)

      if resp.error
        # The API executed, but the script returned an error.

        # Extract the first (and only) set of error details. The values of this
        # object are the script's 'errorMessage' and 'errorType', and an array of
        # stack trace elements.
        error = resp.error.details[0]

        puts "Script error message: #{error['errorMessage']}"

        if error['scriptStackTraceElements']
          # There may not be a stacktrace if the script didn't start executing.
          puts "Script error stacktrace:"
          error['scriptStackTraceElements'].each do |trace|
            puts "\t#{trace['function']}: #{trace['lineNumber']}"
          end
        end
      else
        # The Apps Script returns the ID of the new form
        short_url = resp.response['result']
        if short_url.empty?
          puts "No new form ID returned!"
        else
          puts "New Form ID: #{short_url}"
        end
        return short_url
      end
    rescue Exception => e
      # The API encountered a problem before the script started executing.
      puts "Error calling API: #{e}"
      return ''
    end
  end
end
