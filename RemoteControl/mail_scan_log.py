from sys import argv
if 4 != len(argv):
  print(" Usage: %s <ENV> <Mail From> <Mail To>" %argv[0])
  exit(1)
# Import smtplib for the actual sending function
import smtplib

# Import the email modules we'll need
from email.mime.text import MIMEText

# Open a plain text file for reading.  For this example, assume that
# the text file contains only ASCII characters.
env = argv[1]
textfile = '' %env
fp = open(textfile, 'rb')
# Create a text/plain message
msg = MIMEText(fp.read())
fp.close()

# me == the sender's email address
# you == the recipient's email address
msg['Subject'] = '%s External Scan for GNU/Linux Roles' %env
msg['From'] = argv[2]
msg['To'] = argv[3]

# Send the message via our own SMTP server, but don't include the
# envelope header.
s = smtplib.SMTP('')
s.sendmail(msg['From'], msg['To'], msg.as_string())
s.quit()
