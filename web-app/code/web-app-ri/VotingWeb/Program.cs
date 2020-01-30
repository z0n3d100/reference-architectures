// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.ApplicationInsights;

namespace VotingWeb
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
          Host
            .CreateDefaultBuilder(args)
            .ConfigureWebHostDefaults(webBuilder =>
                webBuilder
                    .ConfigureAppConfiguration((hostingContext, config) =>
                    {
                        var env = hostingContext.HostingEnvironment;
                        if (env.IsDevelopment())
                        {
                            config
                                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: false, reloadOnChange: true);
                        }
                        config.AddEnvironmentVariables();
                    })
                    .ConfigureLogging((hostingContext, logging) =>
                    {
                        if (hostingContext.HostingEnvironment.IsDevelopment())
                        {
                            logging.AddDebug();
                        }

                        logging.AddApplicationInsights((string)hostingContext
                            .Configuration
                            .GetValue(typeof(string), "ApplicationInsights:InstrumentationKey"));
                        logging.AddFilter<ApplicationInsightsLoggerProvider>("Microsoft", LogLevel.Trace);
                        logging.AddFilter<ApplicationInsightsLoggerProvider>("Microsoft", LogLevel.Warning);
                    })
                    .UseStartup<Startup>());
    }
}