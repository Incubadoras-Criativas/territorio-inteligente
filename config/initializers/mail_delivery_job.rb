# Falhas passageiras do servidor de e-mail: tenta de novo, com intervalos crescentes
Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED,
                                         Net::SMTPServerBusy, Net::SMTPAuthenticationError,
                                         wait: :polynomially_longer, attempts: 5
end
