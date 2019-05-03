namespace VotingData.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Data.SqlClient;
    using System.Text;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.Extensions.Logging;
    using VotingData.Models;

    [Route("api/[controller]")]
    [ApiController]
    public class VoteDataController : ControllerBase
    {
        private readonly ILogger<VoteDataController> logger;
        private readonly VotingDBContext _context;
        private readonly string _validOptionsString;

        public VoteDataController(VotingDBContext context, ILogger<VoteDataController> logger)
        {
            this.logger = logger;
            _context = context;
        }

        // GET api/VoteData
        [HttpGet]
        public async Task<ActionResult<IList<Counts>>> Get()
        {
            try
            {
                
                return await _context.Counts.ToListAsync();
            }
            catch (Exception ex) when ( ex is SqlException)
            {         
                logger.LogError(ex.StackTrace);
                return BadRequest("Bad Request");
            }
        }

        [HttpPut("{name}")]

        public async Task<IActionResult> Put(string name)
        {
            try
            {
                var candidate = await _context.Counts.FirstOrDefaultAsync(c => c.Candidate == name);
                if (candidate == null)
                {
                    await _context.Counts.AddAsync(new Counts
                    {
                        Candidate = name,
                        Count = 1
                    });
                }
                else
                {
                    candidate.Count++;
                    _context.Entry(candidate).State = EntityState.Modified;
                }

                await _context.SaveChangesAsync();
                return NoContent();

            }
            catch (Exception ex) when (ex is SqlException || 
                                       ex is DbUpdateException ||
                                       ex is DbUpdateConcurrencyException)
            {
                logger.LogError(ex.StackTrace);
                return BadRequest("Bad Request");
            }

        }



        // DELETE api/VoteData/name

        [HttpDelete("{name}")]

        public async Task<IActionResult> Delete(string name)
        {
            try
            {
                var candidate = await _context.Counts.FirstOrDefaultAsync(c => c.Candidate == name);

                if (candidate != null)
                {
                    _context.Counts.Remove(candidate);
                    await _context.SaveChangesAsync();

                }

                return new OkResult();

            }
            catch (Exception ex) when (ex is SqlException ||
                                    ex is DbUpdateException ||
                                    ex is DbUpdateConcurrencyException)
            {
                logger.LogError(ex.StackTrace);
                return BadRequest("Bad Request");
            }

        }
        
}
}
