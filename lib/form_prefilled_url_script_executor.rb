require 'google/apis/script_v1'
require 'dotenv'
Dotenv.load

class FormPrefilledUrlScriptExecutor
  attr_accessor :client

  def get_prefilled_url_for_latest_responses(formId)

    # Create an execution request object.
    request = Google::Apis::ScriptV1::ExecutionRequest.new(
      function: 'getPrefilledUrlFromLatestResponses',
      parameters: [formId],
      devMode: false
    )

    begin
      # Make the API request.
      resp = client.run_script(ENV['FORM_PREFILLED_URL_SCRIPT_ID'], request)

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
        response = resp.response['result']
        short_url = response['prefilledFormUrl']
        destination_id = response['destinationId']
        if not short_url and not destination_id
          puts "No URL returned!"
        else
          puts "Prefilled Short URL Returned: #{short_url}\nfor destination #{destination_id}"
        end
        return [short_url, destination_id]
      end
    rescue Exception => e
      # The API encountered a problem before the script started executing.
      puts "Error calling API: #{e}"
      return ['','']
    end
  end
end
