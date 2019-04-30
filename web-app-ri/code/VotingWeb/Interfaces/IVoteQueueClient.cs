using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace VotingWeb.Interfaces
{
    public interface IVoteQueueClient
    {
        Task SendVoteAsync(string messageBody);
    }
}
