using System.Net.Http;
using System.Collections.Generic;
using VotingWeb.Models;
using System.Threading.Tasks;
using Newtonsoft.Json;
using VotingWeb.Interfaces;
using System;
using VotingWeb.Exceptions;

namespace VotingWeb.Clients
{
    public class VoteDataClient : IVoteDataClient
    {
        private HttpClient HttpClient { get; set; }

        public VoteDataClient(HttpClient httpClient)
        {
            HttpClient = httpClient;
        }

        public async Task<IList<Counts>> GetCounts()
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get,$"/api/VoteData");
                var response = await HttpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                return JsonConvert.DeserializeObject<IList<Counts>>(await response.Content.ReadAsStringAsync());
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                                 ex is InvalidOperationException ||
                                 ex is HttpRequestException)
            {
                throw new VoteDataException("Request Exception Occurred", ex);
            }


        }

        public async Task<HttpResponseMessage> AddVote(string candidate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Put, $"/api/VoteData/{candidate}");
                return await HttpClient.SendAsync(request);
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                              ex is InvalidOperationException ||
                              ex is HttpRequestException)
            {
                throw new VoteDataException("Request Exception Occurred", ex);
            }

        }

        public async Task DeleteCandidate(string candidate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/VoteData/{candidate}");
                var response = await HttpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                          ex is InvalidOperationException ||
                          ex is HttpRequestException)
            {
                throw new VoteDataException("Request Exception Occurred", ex);
            }

        }
    }
}