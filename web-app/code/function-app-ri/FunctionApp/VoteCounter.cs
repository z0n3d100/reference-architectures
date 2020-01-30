// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Data.SqlClient;
using System.Security;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace FunctionApp
{
    public static class VoteCounter
    {
        [FunctionName("VoteCounter")]
        public static async Task Run(
            [ServiceBusTrigger("votingqueue", Connection = "SERVICEBUS_CONNECTION_STRING")]string myQueueItem,
            ILogger log)
        {
            JObject jObject = JObject.Parse(myQueueItem);
            var id = (int)jObject["Id"];

            try
            {
                var connectionString = Environment.GetEnvironmentVariable("sqldb_connection");
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    var text = "UPDATE dbo.Counts  SET Count = Count + 1 WHERE ID = @ID;";

                    using (SqlCommand cmd = new SqlCommand(text, conn))
                    {
                        cmd.Parameters.AddWithValue("@ID", id);

                        var rows = await cmd.ExecuteNonQueryAsync();
                        if (rows == 0)
                        {
                            log.LogError("id entry not found on the database {id}", id);
                        }
                    }
                }
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                                    ex is SecurityException ||
                                    ex is SqlException)
            {
                log.LogError(ex, "Sql Exception");
            }
        }
    }
}
