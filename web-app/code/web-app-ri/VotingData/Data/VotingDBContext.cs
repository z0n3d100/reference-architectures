using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace VotingData.Models
{
    public class VotingDBContext : DbContext
    {
      
        public VotingDBContext()
        {
        }

        public VotingDBContext(DbContextOptions<VotingDBContext> options)
            : base(options)
        {
        }

        public DbSet<Counts> Counts { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Counts>(entity =>
            {
                entity.Property(e => e.Candidate).IsRequired();
            });
        }
    }
}
