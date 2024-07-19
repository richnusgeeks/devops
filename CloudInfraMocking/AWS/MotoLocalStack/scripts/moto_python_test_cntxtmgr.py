import boto3
from moto import mock_aws

class MyBucket:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def save(self):
        s3 = boto3.client("s3", region_name="us-east-1")
        s3.put_object(Bucket="mybucket", Key=self.name, Body=self.value)

def test_s3_save():
  with mock_aws():

    conn = boto3.resource("s3", region_name="us-east-1")
    conn.create_bucket(Bucket="mybucket")

    bucket = MyBucket("PinkFloyd", "is awesome")
    bucket.save()

    body = conn.Object("mybucket", "PinkFloyd").get()[
        "Body"].read().decode("utf-8")

    assert body == "is awesome"

if "__main__" == __name__:
  test_s3_save()
