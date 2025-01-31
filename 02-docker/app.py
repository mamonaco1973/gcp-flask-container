import json
import os
from flask import Flask, Response, request, jsonify
from azure.cosmos import CosmosClient, exceptions
from azure.identity import DefaultAzureCredential

# Azure Cosmos DB Configuration - Fetching required environment variables
COSMOS_ENDPOINT = os.environ.get("COSMOS_ENDPOINT", "")
DATABASE_NAME = os.environ.get("COSMOS_DATABASE_NAME", "CandidateDatabase")
CONTAINER_NAME = os.environ.get("COSMOS_CONTAINER_NAME", "Candidates")

# Initialize Cosmos DB Client using DefaultAzureCredential for authentication
# This automatically supports Managed Identity authentication
credential = DefaultAzureCredential()
cosmos_client = CosmosClient(COSMOS_ENDPOINT, credential=credential)

# Get the database and container clients
database = cosmos_client.get_database_client(DATABASE_NAME)
container = database.get_container_client(CONTAINER_NAME)

# Initialize Flask application
candidates_app = Flask(__name__)

# Get the instance ID (hostname IP) for identifying the running instance
instance_id = os.popen("hostname -i").read().strip()

@candidates_app.route("/", methods=["GET"])
def default():
    """ Default route: Returns a 400 Bad Request for invalid root-level requests """
    return jsonify({"status": "invalid request"}), 400


@candidates_app.route("/gtg", methods=["GET"])
def gtg():
    """
    Good-To-Go (GTG) health check endpoint.
    If `details` query param is provided, returns instance connectivity details.
    Otherwise, returns a simple 200 status.
    """
    details = request.args.get("details")

    if details:
        return jsonify({"connected": "true", "hostname": instance_id}), 200

    # Ensure consistent MIME type for JSON responses
    return Response(json.dumps({}), status=200, mimetype="application/json")


@candidates_app.route("/candidate/<name>", methods=["GET"])
def get_candidate(name):
    """
    Fetches a candidate by name from the Azure Cosmos DB.
    Returns 200 with candidate details if found, otherwise 404 Not Found.
    """
    try:
        # Query Cosmos DB for the given candidate name
        query = "SELECT c.CandidateName FROM c WHERE c.CandidateName = @name"
        parameters = [{"name": "@name", "value": name}]
        response = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))

        if not response:
            raise ValueError("Candidate not found")

        # Return JSON response with correct MIME type
        return Response(json.dumps(response), status=200, mimetype="application/json")

    except Exception as e:
        return jsonify({"error": "Not Found", "message": str(e)}), 404


@candidates_app.route("/candidate/<name>", methods=["POST"])
def post_candidate(name):
    """
    Creates or updates a candidate entry in Cosmos DB.
    Returns 200 with the stored candidate's name upon success.
    """
    try:
        # Construct the candidate item for storage
        item = {"id": name, "CandidateName": name}

        # Insert or update item in Cosmos DB
        container.upsert_item(item)

    except exceptions.CosmosHttpResponseError as ex:
        return jsonify({"error": "Unable to update", "message": str(ex)}), 500

    # Return successful response with correct MIME type
    return Response(json.dumps({"CandidateName": name}), status=200, mimetype="application/json")


@candidates_app.route("/candidates", methods=["GET"])
def get_candidates():
    """
    Retrieves all candidates stored in Cosmos DB.
    Returns 200 with candidate list if successful, otherwise 404 Not Found.
    """
    try:
        # Query to fetch all candidate names
        query = "SELECT c.CandidateName FROM c"
        response = list(container.query_items(query=query, enable_cross_partition_query=True))

        if not response:
            raise ValueError("No candidates found")

        # Return JSON response with correct MIME type
        return Response(json.dumps(response), status=200, mimetype="application/json")

    except Exception as e:
        return jsonify({"error": "Not Found", "message": str(e)}), 404


