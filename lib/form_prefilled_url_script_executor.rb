require 'google/apis/script_v1'
require 'google/api_client/auth/key_utils'
require 'googleauth'
require 'fileutils'
require 'base64'
require 'dotenv'
Dotenv.load

class FormPrefilledUrlScriptExecutor

  SCOPES = ['https://www.googleapis.com/auth/drive',
              'https://spreadsheets.google.com/feeds',
              'https://www.googleapis.com/auth/forms',
              'https://www.googleapis.com/auth/urlshortener']

  def get_prefilled_url_for_latest_responses(formId)
    key = Google::APIClient::KeyUtils.load_from_pkcs12(
      Base64.decode64(ENV['P12B64']), ENV['GOOGLE_SERVICE_ACCT_PASS'])
    service = Google::Apis::ScriptV1::ScriptService.new
    service.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => SCOPES,
      :issuer => ENV['GOOGLE_SERVICE_ACCOUNT_ISSUER_EMAIL'],
      :signing_key => key)
    auth_client = service.authorization.dup
    auth_client.sub = ENV['GOOGLE_SERVICE_ACCOUNT_USER_EMAIL']
    auth_client.fetch_access_token!
    service.authorization = auth_client

    # Create an execution request object.
    request = Google::Apis::ScriptV1::ExecutionRequest.new(
      function: 'getPrefilledUrlFromLatestResponses',
      parameters: [formId],
      devMode: false
    )

    begin
      # Make the API request.
      resp = service.run_script(ENV['FORM_PREFILLED_URL_SCRIPT_ID'], request)

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
