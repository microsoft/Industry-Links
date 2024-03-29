public class Script : ScriptBase
{
    public override async Task<HttpResponseMessage> ExecuteAsync()
    {
        try
        {
            // Update the request by retrieiving a new access token
            await this.UpdateRequestAuth().ConfigureAwait(false);
            var response = await this.Context.SendAsync(this.Context.Request, this.CancellationToken).ConfigureAwait(false);
            return response;
        }
        catch (ConnectorException ex)
        {
            var response = new HttpResponseMessage(ex.StatusCode)
            {
                Content = CreateJsonContent(ex.Message)
            };
            return response;
        }
    }

    private async Task UpdateRequestAuth()
    {
        string content;

        var headers = this.Context.Request.Headers;

        string uri = headers.GetValues("tokenUrl").FirstOrDefault();

        string body = $"grant_type=client_credentials&client_id={headers.GetValues("clientId").FirstOrDefault()}&client_secret={headers.GetValues("clientSecret").FirstOrDefault()}";

        bool headerContainsScope = headers.Contains("scope");
        if(headerContainsScope){
            body = body + $"&scope={headers.GetValues("scope").FirstOrDefault()}";
        }

        using var tokenRequest = new HttpRequestMessage(HttpMethod.Post, uri)
        {
            Content = new StringContent(body, Encoding.UTF8, "application/x-www-form-urlencoded")
        };

        try
        {
            using var tokenResponse = await this.Context.SendAsync(tokenRequest, this.CancellationToken).ConfigureAwait(false);
            content = await tokenResponse.Content.ReadAsStringAsync().ConfigureAwait(false);

            if (tokenResponse.IsSuccessStatusCode)
            {
                var jsonContent = JObject.Parse(content);
                string access_token = jsonContent["access_token"].ToString();

                if (!string.IsNullOrEmpty(access_token))
                {
                    this.Context.Request.Headers.Remove("tokenUrl");
                    if(headerContainsScope) this.Context.Request.Headers.Remove("scope");
                    this.Context.Request.Headers.Remove("clientId");
                    this.Context.Request.Headers.Remove("clientSecret");
                    this.Context.Request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", access_token);
                }
                else
                {
                    throw new ConnectorException(HttpStatusCode.BadGateway, "Unable to get access_token from the response: " + content);
                }
            }
            else
            {
                throw new ConnectorException(tokenResponse.StatusCode, content);
            }
        }
        catch (HttpRequestException ex)
        {
            throw new ConnectorException(HttpStatusCode.BadGateway, "Unable to get tokenResponse: " + ex.Message, ex);
        }
    }

    public class ConnectorException : Exception
    {
        public ConnectorException(
                HttpStatusCode statusCode,
                string message,
                Exception innerException = null)
                : base(
                                message,
                                innerException)
        {
            this.StatusCode = statusCode;
        }

        public HttpStatusCode StatusCode { get; }

        public override string ToString()
        {
            var error = new StringBuilder($"ConnectorException: Status code={this.StatusCode}, Message='{this.Message}'");
            var inner = this.InnerException;
            var level = 0;
            while (inner != null && level < 10)
            {
                level += 1;
                error.AppendLine($"Inner exception {level}: {inner.Message}");
                inner = inner.InnerException;
            }

            error.AppendLine($"Stack trace: {this.StackTrace}");
            return error.ToString();
        }
    }
}