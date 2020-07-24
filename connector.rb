{
  title: "Dropbox",
  connection: {
    fields: [
      {
        name: "client_id",
        hint: "https://www.dropbox.com/developers/apps
              Redirect URI is https://www.workato.com/oauth/callback",
              optional: false
      },
      {
        name: "client_secret",
        hint: "https://www.dropbox.com/developers/apps",
        optional: false,
        control_type: "password"
      }
    ],
    authorization: {
      type: "oauth2",
      authorization_url: lambda do |connection|
        params = {
          response_type: "code",
          client_id: connection["client_id"],
          redirect_uri: "https://www.workato.com/oauth/callback",
          token_access_type: "offline"
        }.to_param

        "https://www.dropbox.com/oauth2/authorize?" + params
      end,
      acquire: lambda do |connection, auth_code|
        response = post("https://api.dropboxapi.com/oauth2/token").
          payload(
            code: auth_code,
            grant_type: "authorization_code",
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            redirect_uri: "https://www.workato.com/oauth/callback").
            request_format_www_form_urlencoded
        [response, nil, nil]
      end,
      refresh: lambda do |connection, refresh_token|
        post("https://accounts.google.com/o/oauth2/token").
          payload(
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            grant_type: "refresh_token",
            refresh_token: refresh_token).
            request_format_www_form_urlencoded
      end,
      apply: lambda do |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    }
  },
  test: lambda do |_connection|
    true
  end,
  actions: {
    create_shared_link: {
      title: "Create shared link",
      input_fields: lambda do |_object_definitions|
        [
          {
            "control_type": "text",
            "label": "Path",
            "type": "string",
            "name": "path",
            "hint": "Exact path to file, starts with forward-slash",
            "details": {
              "real_name": "path"
            }
          },
          {
            "properties": [
              {
                "control_type": "text",
                "label": "Requested visibility",
                "type": "string",
                "name": "requested_visibility",
                "details": {
                  "real_name": "requested_visibility"
                }
              },
              {
                "control_type": "text",
                "label": "Audience",
                "type": "string",
                "name": "audience",
                "details": {
                  "real_name": "audience"
                }
              },
              {
                "control_type": "text",
                "label": "Access",
                "type": "string",
                "name": "access",
                "details": {
                  "real_name": "access"
                }
              },
              {
                "control_type": "text",
                "label": "Expires",
                "type": "string",
                "name": "expires",
                "details": {
                  "real_name": "expires"
                }
              }
            ],
            "label": "Settings",
            "type": "object",
            "name": "settings",
            "details": {
              "real_name": "settings"
            }
          }
        ]
      end,
      execute: lambda do |connection, input|
        listed_links = post("https://api.dropboxapi.com/2/sharing/list_shared_links").
          payload({"path": input["path"]})
        if listed_links["links"].length == 1
          deleting = post("https://api.dropboxapi.com/2/sharing/revoke_shared_link").
            payload({"url": listed_links["links"][0]["url"]})
          puts(deleting)
        end
        post("https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings").
          payload(input)
      end,
      output_fields: lambda do |object_definitions|
        [
          {
            "control_type": "text",
            "label": ".tag",
            "type": "string",
            "name": ".tag"
          },
          {
            "control_type": "text",
            "label": "URL",
            "type": "string",
            "name": "url"
          },
          {
            "control_type": "text",
            "label": "ID",
            "type": "string",
            "name": "id"
          },
          {
            "control_type": "text",
            "label": "Name",
            "type": "string",
            "name": "name"
          },
          {
            "control_type": "text",
            "label": "Expires",
            "render_input": "date_time_conversion",
            "parse_output": "date_time_conversion",
            "type": "date_time",
            "name": "expires"
          },
          {
            "control_type": "text",
            "label": "Path lower",
            "type": "string",
            "name": "path_lower"
          },
          {
            "properties": [
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": ".tag",
                    "type": "string",
                    "name": ".tag"
                  }
                ],
                "label": "Resolved visibility",
                "type": "object",
                "name": "resolved_visibility"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": ".tag",
                    "type": "string",
                    "name": ".tag"
                  }
                ],
                "label": "Requested visibility",
                "type": "object",
                "name": "requested_visibility"
              },
              {
                "control_type": "text",
                "label": "Can revoke",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Can revoke",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "can_revoke"
                },
                "type": "boolean",
                "name": "can_revoke"
              },
              {
                "name": "visibility_policies",
                "type": "array",
                "of": "object",
                "label": "Visibility policies",
                "properties": [
                  {
                    "properties": [
                      {
                        "control_type": "text",
                        "label": ".tag",
                        "type": "string",
                        "name": ".tag"
                      }
                    ],
                    "label": "Policy",
                    "type": "object",
                    "name": "policy"
                  },
                  {
                    "properties": [
                      {
                        "control_type": "text",
                        "label": ".tag",
                        "type": "string",
                        "name": ".tag"
                      }
                    ],
                    "label": "Resolved policy",
                    "type": "object",
                    "name": "resolved_policy"
                  },
                  {
                    "control_type": "text",
                    "label": "Allowed",
                    "render_input": {},
                    "parse_output": {},
                    "toggle_hint": "Select from option list",
                    "toggle_field": {
                      "label": "Allowed",
                      "control_type": "text",
                      "toggle_hint": "Use custom value",
                      "type": "boolean",
                      "name": "allowed"
                    },
                    "type": "boolean",
                    "name": "allowed"
                  }
                ]
              },
              {
                "control_type": "text",
                "label": "Can set expiry",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Can set expiry",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "can_set_expiry"
                },
                "type": "boolean",
                "name": "can_set_expiry"
              },
              {
                "control_type": "text",
                "label": "Can remove expiry",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Can remove expiry",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "can_remove_expiry"
                },
                "type": "boolean",
                "name": "can_remove_expiry"
              },
              {
                "control_type": "text",
                "label": "Allow download",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Allow download",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "allow_download"
                },
                "type": "boolean",
                "name": "allow_download"
              },
              {
                "control_type": "text",
                "label": "Can allow download",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Can allow download",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "can_allow_download"
                },
                "type": "boolean",
                "name": "can_allow_download"
              },
              {
                "control_type": "text",
                "label": "Can disallow download",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Can disallow download",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "can_disallow_download"
                },
                "type": "boolean",
                "name": "can_disallow_download"
              },
              {
                "control_type": "text",
                "label": "Allow comments",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Allow comments",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "allow_comments"
                },
                "type": "boolean",
                "name": "allow_comments"
              },
              {
                "control_type": "text",
                "label": "Team restricts comments",
                "render_input": {},
                "parse_output": {},
                "toggle_hint": "Select from option list",
                "toggle_field": {
                  "label": "Team restricts comments",
                  "control_type": "text",
                  "toggle_hint": "Use custom value",
                  "type": "boolean",
                  "name": "team_restricts_comments"
                },
                "type": "boolean",
                "name": "team_restricts_comments"
              },
              {
                "name": "audience_options",
                "type": "array",
                "of": "object",
                "label": "Audience options",
                "properties": [
                  {
                    "properties": [
                      {
                        "control_type": "text",
                        "label": ".tag",
                        "type": "string",
                        "name": ".tag"
                      }
                    ],
                    "label": "Audience",
                    "type": "object",
                    "name": "audience"
                  },
                  {
                    "control_type": "text",
                    "label": "Allowed",
                    "render_input": {},
                    "parse_output": {},
                    "toggle_hint": "Select from option list",
                    "toggle_field": {
                      "label": "Allowed",
                      "control_type": "text",
                      "toggle_hint": "Use custom value",
                      "type": "boolean",
                      "name": "allowed"
                    },
                    "type": "boolean",
                    "name": "allowed"
                  }
                ]
              }
            ],
            "label": "Link permissions",
            "type": "object",
            "name": "link_permissions"
          },
          {
            "control_type": "text",
            "label": "Preview type",
            "type": "string",
            "name": "preview_type"
          },
          {
            "control_type": "text",
            "label": "Client modified",
            "render_input": "date_time_conversion",
            "parse_output": "date_time_conversion",
            "type": "date_time",
            "name": "client_modified"
          },
          {
            "control_type": "text",
            "label": "Server modified",
            "render_input": "date_time_conversion",
            "parse_output": "date_time_conversion",
            "type": "date_time",
            "name": "server_modified"
          },
          {
            "control_type": "text",
            "label": "Rev",
            "type": "string",
            "name": "rev"
          },
          {
            "control_type": "number",
            "label": "Size",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "size"
          }
        ]
      end
    }
  }
}
