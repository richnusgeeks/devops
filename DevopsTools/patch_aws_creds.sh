set -eu

scrpt='variables.json'
botocnfg="$HOME/.aws/credentials"
sctn='<Boto Profile Section>'
awsaki=$(sed -n "/^ *\[$sctn\]/,/^ *$/p" $botocnfg | grep aws_access_key_id | awk -F"=" '{print $2}' | sed 's/^ *//' | sed 's/ *$//')
awssaki=$(sed -n "/^ *\[$sctn\]/,/^ *$/p" $botocnfg | grep aws_secret_access_key | awk -F"=" '{print $2}' | sed 's/^ *//' | sed 's/ *$//')
sed -i '' -e "s/<AwsAccessKey>/$awsaki/" \
          -e "s/<AwsSecretKey>/$awssaki/" \
          "$scrpt"
