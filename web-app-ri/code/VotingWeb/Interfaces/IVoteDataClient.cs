using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using VotingWeb.Models;

namespace VotingWeb.Interfaces
{
    public interface IVoteDataClient
    {
        Task<IList<Counts>> GetCounts();

        Task<HttpResponseMessage> AddVote(string candidate);

        Task DeleteCandidate(string candidate);


    }
}
