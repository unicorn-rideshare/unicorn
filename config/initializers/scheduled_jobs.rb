Resque.set_schedule(ProviderBulkDailyPayoutJob.name, { class: ProviderBulkDailyPayoutJob.name,
                                                   cron: '0 8 * * *',
                                                   persist: true })

Resque.set_schedule(RequeueFailuresJob.name, { class: RequeueFailuresJob.name,
                                               cron: '*/10 * * * *',
                                               persist: true })

Resque.set_schedule(PurgeInvalidDevicesJob.name, { class: PurgeInvalidDevicesJob.name,
                                                   cron: '00 00 * * *',
                                                   persist: true })

Resque.reload_schedule!
