require 'appwrite'
require 'meilisearch'

def main(context)

  client = Appwrite::Client.new
  client
    .set_endpoint('https://cloud.appwrite.io/v1')
    .set_project(ENV['APPWRITE_FUNCTION_PROJECT_ID'])
    .set_key(ENV['APPWRITE_API_KEY'])

  meilisearch = MeiliSearch::Client.new(ENV['MEILISEARCH_ENDPOINT'], ENV['MEILISEARCH_ADMIN_API_KEY'])

  index_name = ENV['MEILISEARCH_INDEX_NAME']

  database = Appwrite::Database.new(client)

  index = meilisearch.index(index_name)

  cursor = nil

  begin
    queries = [Appwrite::Query.new.set_limit(100)]

    if cursor
      queries.push(Appwrite::Query.new.set_cursor(cursor))
    end

    documents = database.list_documents(
      ENV['APPWRITE_DATABASE_ID'],
      ENV['APPWRITE_COLLECTION_ID'],
      queries
    )

    if documents['documents'].length > 0
      cursor = documents['documents'].last['$id']
    else
      context.error('No more documents found.')
      cursor = nil
      break
    end

    context.log("Syncing chunk of #{documents['documents'].length} documents ...")
    index.add_documents(documents['documents'], primary_key: '$id')
  end while cursor

  context.log('Sync finished.')

  response = {
    'message' => 'Sync finished.',
    'status' => 'success'
  }

  context.response.set_body(response.to_json)

  return context.response
end
