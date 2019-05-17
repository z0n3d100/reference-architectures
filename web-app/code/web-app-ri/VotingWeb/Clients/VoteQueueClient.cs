using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.ServiceBus.Management;
using Microsoft.Azure.ServiceBus.Core;
//using Microsoft.ServiceBus.Messaging;
//using Microsoft.ServiceBus;
using System.Threading.Tasks;
using System.Text;
using VotingWeb.Interfaces;
using VotingWeb.Exceptions;

namespace VotingWeb.Clients
{
    public  class VoteQueueClient: IVoteQueueClient
    {
        private static IQueueClient queueClient;
        private string sbConnectionString;
        private string queueName;

        public VoteQueueClient(string connectionString,string queueName)
        {
            try
            {
                this.sbConnectionString = connectionString;
                this.queueName = queueName;
                queueClient = new QueueClient(sbConnectionString, queueName);
            }
            catch (Exception ex) when (ex is ArgumentException ||
                              ex is ServiceBusException ||
                              ex is UnauthorizedAccessException ||
                              ex is ArgumentNullException)
            {
                throw new VoteQueueException("Initialization Error for service bus", ex);

            }

        }

   

        public async Task SendVoteAsync(string messageBody)
        {

            try
            {
                var message = new Message(Encoding.UTF8.GetBytes(messageBody))
                {
                    ContentType = "application/json",
                };

                await queueClient.SendAsync(message);
            }
            catch (Exception ex) when (ex is ArgumentException ||
                                 ex is ServiceBusException ||
                                 ex is UnauthorizedAccessException ||
                                 ex is ServerBusyException ||
                                 ex is ServiceBusTimeoutException)
            {
                throw new VoteQueueException("Service Bus Exception occurred with sending message to queue",ex);
                            
            }

        }

       
    }
   
}