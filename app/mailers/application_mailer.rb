class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Território Inteligente <nao-responda@example.com>")
  layout "mailer"
end
