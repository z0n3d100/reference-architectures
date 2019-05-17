// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

namespace VotingWeb.Controllers
{
    using System;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using VotingWeb.Interfaces;
    using VotingWeb.Exceptions;

    [Produces("application/json")]
    [Route("api/[controller]")]
    public class VotesController : Controller
    {
        private readonly ILogger<VotesController> logger;
        private readonly IVoteDataClient client;
        private readonly IVoteQueueClient queueClient;
        private readonly IAdRepository repositoryClient;
        public VotesController(IVoteDataClient client,
                               IVoteQueueClient queueClient,
                               ILogger<VotesController> logger,
                               IAdRepository repositoryClient)
        {
            this.client = client;
            this.queueClient = queueClient;
            this.logger = logger;
            this.repositoryClient = repositoryClient;
        }

        // GET: api/Votes
        [HttpGet("")]
        public async Task<IActionResult> Get()
        {
            try {
                 return this.Json(await this.client.GetCounts());
            }
            catch (Exception ex) when (ex is VoteDataException)
            {
                logger.LogError(ex.InnerException,ex.Message);
                return BadRequest("Bad Request");
            }
        }

        // PUT: api/Votes/Add/name
        [HttpPut("{name}")]
        [Route("[action]/{name}")]
        public async Task<IActionResult> Add(string name)
        {
            try
            {           
                var response = await this.client.AddVote(name);
                if (response.IsSuccessStatusCode) return this.Ok();
                var errorMessage = await response.Content.ReadAsStringAsync();
                return BadRequest(errorMessage);
            }
            catch (Exception ex) when (ex is VoteDataException)
            {
                logger.LogError(ex.InnerException,ex.Message);
                return BadRequest("Bad Request");
            }

        }


        // PUT: api/Votes/Vote/id
        [HttpPut("{id}")]
        [Route("[action]/{id}")]
        public async Task<IActionResult> Vote(int id)
        {

            try
            {                              
                var data = new { Id = id };
                await queueClient.SendVoteAsync(JsonConvert.SerializeObject(data));
                return this.Ok();
            }
            catch (Exception ex) when (ex is VoteQueueException)
            {
                logger.LogError(ex.InnerException,ex.Message);
                return BadRequest("Bad Request");
            }
    
        }

        // DELETE: api/Votes/name
        [HttpDelete("{name}")]
        public async Task<IActionResult> Delete(string name)
        {
            try
            {
                await this.client.DeleteCandidate(name);
                return new OkResult();
            }
            catch (Exception ex) when (ex is VoteQueueException)
            {
                logger.LogError(ex.InnerException,ex.Message);
                return BadRequest("Bad Request");
            }
        }


        [HttpGet("{cache}")]
        public async Task<IActionResult> Cache()
        {
            try
            {
                return this.Json(await this.repositoryClient.GetAds());
            }
            catch (Exception ex) when (ex is AdRepositoryException)
            {
                logger.LogError(ex.InnerException,ex.Message);
                return BadRequest("Bad Request");
            }
        }
    }
    
}