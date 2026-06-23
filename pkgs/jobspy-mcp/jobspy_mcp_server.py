#!/usr/bin/env python3
import json
import sys
import os
from jobspy import scrape_jobs

TOOLS = [
    {
        "name": "search_jobs",
        "description": "Search for jobs on LinkedIn, Indeed, and other job boards",
        "inputSchema": {
            "type": "object",
            "properties": {
                "search_term": {
                    "type": "string",
                    "description": "Job title, keywords, or boolean query (e.g. 'software engineer', 'Atlassian developer Java')"
                },
                "location": {
                    "type": "string",
                    "description": "City, state, or country (e.g. 'Spain', 'Madrid', 'Remote')"
                },
                "site_names": {
                    "type": "array",
                    "items": {"type": "string", "enum": ["linkedin", "indeed", "glassdoor", "google", "zip_recruiter"]},
                    "description": "Job boards to search (default: linkedin, indeed)"
                },
                "hours_old": {
                    "type": "integer",
                    "description": "Only show jobs posted within this many hours (default: 72)"
                },
                "results_wanted": {
                    "type": "integer",
                    "description": "Number of results per site (default: 20)"
                },
                "is_remote": {
                    "type": "boolean",
                    "description": "Filter for remote jobs only"
                },
                "job_type": {
                    "type": "string",
                    "enum": ["fulltime", "parttime", "internship", "contract"],
                    "description": "Filter by employment type"
                },
                "country_indeed": {
                    "type": "string",
                    "description": "Country for Indeed/Glassdoor search (e.g. 'Spain', 'USA', 'UK')"
                },
                "distance": {
                    "type": "integer",
                    "description": "Search radius in miles (default: 50)"
                }
            },
            "required": ["search_term"]
        }
    },
    {
        "name": "search_google_jobs",
        "description": "Search for jobs via Google Jobs",
        "inputSchema": {
            "type": "object",
            "properties": {
                "google_search_term": {
                    "type": "string",
                    "description": "Exact search term as typed in Google Jobs search box"
                },
                "results_wanted": {
                    "type": "integer",
                    "description": "Number of results (default: 10)"
                }
            },
            "required": ["google_search_term"]
        }
    }
]

def handle_search_jobs(args):
    site_names = args.get("site_names", ["linkedin", "indeed"])
    results_wanted = args.get("results_wanted", 20)
    kwargs = {
        "site_name": site_names,
        "search_term": args["search_term"],
        "results_wanted": results_wanted,
        "verbose": 0,
    }
    if "location" in args:
        kwargs["location"] = args["location"]
    if "hours_old" in args:
        kwargs["hours_old"] = args["hours_old"]
    if "is_remote" in args:
        kwargs["is_remote"] = args["is_remote"]
    if "job_type" in args:
        kwargs["job_type"] = args["job_type"]
    if "country_indeed" in args:
        kwargs["country_indeed"] = args["country_indeed"]
    if "distance" in args:
        kwargs["distance"] = args["distance"]

    try:
        jobs_df = scrape_jobs(**kwargs)
        if jobs_df.empty:
            return {"content": [{"type": "text", "text": "No jobs found matching your criteria."}]}
        jobs_json = jobs_df.fillna("").to_dict(orient="records")
        summary = f"Found {len(jobs_json)} jobs:\n\n"
        for i, job in enumerate(jobs_json[:results_wanted], 1):
            summary += f"### {i}. {job.get('title', 'N/A')} @ {job.get('company', 'N/A')}\n"
            summary += f"   **Site:** {job.get('site', 'N/A')} | **Location:** {job.get('location', 'N/A')}\n"
            if job.get('job_type'):
                summary += f"   **Type:** {job['job_type']}"
            if job.get('min_amount') or job.get('max_amount'):
                interval = job.get('interval', 'yearly')
                min_s = job.get('min_amount', '')
                max_s = job.get('max_amount', '')
                summary += f" | **Salary:** {min_s}-{max_s}/{interval}"
            summary += "\n"
            if job.get('job_url'):
                summary += f"   **URL:** {job['job_url']}\n"
            if job.get('description'):
                desc = job['description'][:500]
                summary += f"   **Description:** {desc}...\n"
            summary += "\n"
        return {"content": [{"type": "text", "text": summary}]}
    except Exception as e:
        return {"content": [{"type": "text", "text": f"Error searching jobs: {str(e)}"}]}

def handle_search_google_jobs(args):
    results_wanted = args.get("results_wanted", 10)
    try:
        jobs_df = scrape_jobs(
            site_name=["google"],
            google_search_term=args["google_search_term"],
            results_wanted=results_wanted,
            verbose=0,
        )
        if jobs_df.empty:
            return {"content": [{"type": "text", "text": "No Google Jobs found matching your criteria."}]}
        jobs_json = jobs_df.fillna("").to_dict(orient="records")
        summary = f"Found {len(jobs_json)} Google Jobs:\n\n"
        for i, job in enumerate(jobs_json[:results_wanted], 1):
            summary += f"### {i}. {job.get('title', 'N/A')} @ {job.get('company', 'N/A')}\n"
            summary += f"   **Location:** {job.get('location', 'N/A')}\n"
            if job.get('job_url'):
                summary += f"   **URL:** {job['job_url']}\n"
            summary += "\n"
        return {"content": [{"type": "text", "text": summary}]}
    except Exception as e:
        return {"content": [{"type": "text", "text": f"Error searching Google Jobs: {str(e)}"}]}

HANDLERS = {
    "search_jobs": handle_search_jobs,
    "search_google_jobs": handle_search_google_jobs,
}

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--list-tools":
        print(json.dumps(TOOLS))
        return

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        msg_id = msg.get("id")
        method = msg.get("method")
        params = msg.get("params", {})

        if method == "tools/call":
            tool_name = params.get("name")
            arguments = params.get("arguments", {})
            handler = HANDLERS.get(tool_name)
            if handler:
                result = handler(arguments)
            else:
                result = {"content": [{"type": "text", "text": f"Unknown tool: {tool_name}"}]}
            response = {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": result,
            }
        elif method == "tools/list":
            response = {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {"tools": TOOLS},
            }
        elif method == "initialize":
            response = {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "jobspy-mcp", "version": "1.0.0"},
                },
            }
        elif method == "notifications/initialized":
            continue
        else:
            response = {
                "jsonrpc": "2.0",
                "id": msg_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            }

        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()

if __name__ == "__main__":
    main()
