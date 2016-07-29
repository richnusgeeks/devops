#! /usr/bin/env python
############################################################################
# File name : dumpawsinfo.py
# Purpose : Dump various AWS info 
# Usages : dumpawsinfo [-i|--instances|-s|--securitygps|-k|--keypairs|
#                       -u|--subnets|-b|--s3buckets|-q|--sqsqueues|
#                       -r|--redshift|-e|--emrclstrs|-n|--kinesis]
#                       <BotoProfileName>
# Start date : 10/09/2014
# End date : dd/mm/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : 
# License : GNU GPL v3
# Version : 0.0.1
# Modification history : 
############################################################################

def _prntErrWarnInfo(smsg, smsgtype = 'err', bresume = False):
    '''
        Global routine to print error/warning/info strings and resume/exit.
    '''

    derrwarninfo = {
                    'err'  : ' ERROR',
                    'warn' : ' WARNING',
                    'info' : ' INFO',
                   }  

    if not isinstance(smsg, str):

        print
        print (' Error : Invalid message type, '
               + 'please enter string.')
        print
        return False

    if smsgtype not in derrwarninfo.keys():
        
        print
        print (' Error : Invalid message type, '
               + 'please choose from \'err\', \'warn\', \'info\'.')
        print
        return False

    print
    print derrwarninfo[smsgtype] + ' : ' + smsg
    print

    if not bresume:
        print ' exiting ...'
        exit(-1)
    else:
        return True

try:
    from pygenericroutines import PyGenericRoutines, prntErrWarnInfo
except Exception, e:
    serr = ('%s, %s'
            %('from pygenericroutines import PyGenericRoutines', str(e)))
    _prntErrWarnInfo(serr)

try:
    import boto, boto.ec2, boto.ec2.elb
except Exception, e:
    serr = '%s, %s' %('import boto', str(e))
    prntErrWarnInfo(serr)

try:
    from boto.vpc import VPCConnection
except Exception, e:
    serr = '%s, %s' %('from boto.vpc import VPCConnection', str(e))
    prntErrWarnInfo(serr)

try:
    import time
except Exception, e:
    serr = '%s, %s' %('import time', str(e))
    prntErrWarnInfo(serr)


class DumpAwsInfo():
  '''
    This class provides the functionalities to dump various AWS
    info.
  '''

  def __init__(self):
      '''
          Class constructor to initialize required data structures.
      '''
      
      self.opygenericroutines = PyGenericRoutines(self.__class__.__name__)
      self.opygenericroutines.setupLogging()
      self.bcnfgfloprtn = self.opygenericroutines.setupConfigFlOprtn()
      self.sclsnme     = self.__class__.__name__
      self.botoprfl = "default"
      self.iflag = False
      self.sflag = False
      self.kflag = False
      self.uflag = False
      self.bflag = False
      self.qflag = False
      self.rflag = False
      self.eflag = False
      self.nflag = False
      self.mflag = False
      self.trsinfo = (
                       'ClusterIdentifier',
                       'ClusterCreateTime',
                       'ClusterStatus',
                       'DBName',
                       'MasterUsername',
                       'Endpoint',
                       'NodeType',
                       'NumberOfNodes',
                       'ClusterNodes',
                       'PubliclyAccessible',
                       'VpcSecurityGroups',
                       'ElasticIpStatus',
                       #'ClusterPublicKey',
                       'ModifyStatus',
                       #'PendingModifiedValues',
                       'VpcId',
                       'ClusterVersion',
                       'AutomatedSnapshotRetentionPeriod',
                       'ClusterParameterGroups',
                       'PreferredMaintenanceWindow',
                       'HsmStatus',
                       'RestoreStatus',
                       'AllowVersionUpgrade',
                       'ClusterSubnetGroupName',
                       'ClusterSecurityGroups',
                       'AvailabilityZone',
                       'Encrypted',
                       'ClusterRevisionNumber',
                       'ClusterSnapshotCopyStatus',
                     )
      self.tsqsinfo = ( 
                        'ApproximateNumberOfMessagesNotVisible',
                        'MessageRetentionPeriod',
                        'ApproximateNumberOfMessagesDelayed',
                        'MaximumMessageSize',
                        'CreatedTimestamp',
                        'ApproximateNumberOfMessages',
                        'ReceiveMessageWaitTimeSeconds',
                        'DelaySeconds',
                        'VisibilityTimeout',
                        'LastModifiedTimestamp',
                        #'QueueArn',
                      )
      self.doptsargs = {
                         'instances' : {
                                        'shortopt' : '-i',
                                        'longopt'  : '--instances',
                                        'dest'     : 'iflag',
                                        'action'   : 'store_true',
                                        'help'     : 'show EC2/VPC instances',
                                       },
                         'securitygps' : {
                                          'shortopt' : '-s',
                                          'longopt'  : '--securitygps',
                                          'dest'     : 'sflag',
                                          'action'   : 'store_true',
                                          'help'     : 'show EC2/VPC security groups',
                                         },
                         'keypairs' : {
                                      'shortopt' : '-k',
                                      'longopt'  : '--keypairs',
                                      'dest'     : 'kflag',
                                      'action'   : 'store_true',
                                      'help'     : 'show EC2/VPC IAM keypairs',
                                     },
                         'subnets' : {
                                      'shortopt' : '-u',
                                      'longopt'  : '--subnets',
                                      'dest'     : 'uflag',
                                      'action'   : 'store_true',
                                      'help'     : 'show VPC subnets',
                                     },
                         's3buckets' : {
                                        'shortopt' : '-b',
                                        'longopt'  : '--s3buckets',
                                        'dest'     : 'bflag',
                                        'action'   : 'store_true',
                                        'help'     : 'show S3 buckets',
                                       },
                         'sqsqueues' : {
                                        'shortopt' : '-q',
                                        'longopt'  : '--sqsqueues',
                                        'dest'     : 'qflag',
                                        'action'   : 'store_true',
                                        'help'     : 'show SQS queues',
                                       },
                         'redshift' : {
                                       'shortopt' : '-r',
                                       'longopt'  : '--redshift',
                                       'dest'     : 'rflag',
                                       'action'   : 'store_true',
                                       'help'     : 'show Redshift clusters',
                                      },
                         'emrclstrs' : {
                                       'shortopt' : '-e',
                                       'longopt'  : '--emrclstrs',
                                       'dest'     : 'eflag',
                                       'action'   : 'store_true',
                                       'help'     : 'show EMR clusters',
                                      },
                         'kinesis' : {
                                       'shortopt' : '-n',
                                       'longopt'  : '--kinesis',
                                       'dest'     : 'nflag',
                                       'action'   : 'store_true',
                                       'help'     : 'show Kinesis streams',
                                     },
                         'ami'     : {
                                       'shortopt' : '-m',
                                       'longopt'  : '--ami',
                                       'dest'     : 'mflag',
                                       'action'   : 'store_true',
                                       'help'     : 'show AMIs',
                                     },
                       }

      self.susage = '''usage: %prog [-i|--instances|-s|--securitygps|-k|--keypairs|
                       -u|--subnets|-b|--s3buckets|-q|--sqsqueues|
                       -r|--redshift|-e|--emrclstrs|-n|--kinesis|
                       -m|--ami] <BotoProfileName>'''

  def parseOptsArgs(self):
    '''
      Method to parse command line options and arguments.
    '''

    options = None
    args    = None
    try:
      (options, args) = self.opygenericroutines.parseCmdLine( \
                          self.doptsargs, \
                          tposargs = tuple(self.botoprfl), \
                          susage = self.susage, \
                          bexactposargs = False)
    except Exception, e:
      serr = (self.sclsnme + '::' + 'parseOptsArgs(...)' + ':'
              + 'parseCmdLine(...)' + ', ' + str(e))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)
      return False

    if options.iflag:
      self.iflag = options.iflag

    if options.sflag:
      self.sflag = options.sflag

    if options.kflag:
      self.kflag = options.kflag

    if options.uflag:
      self.uflag = options.uflag

    if options.bflag:
      self.bflag = options.bflag

    if options.qflag:
      self.qflag = options.qflag

    if options.rflag:
      self.rflag = options.rflag

    if options.eflag:
      self.eflag = options.eflag

    if options.nflag:
      self.nflag = options.nflag

    if options.mflag:
      self.mflag = options.mflag

    if args and args[0] != self.botoprfl:
      self.botoprfl = args[0]

    return True

  def dumpInstances(self):
    '''
      Method to dump EC2/VPC instances and related info.
    '''
    try:
      rgns = [i.name  for i in boto.ec2.regions() if not i.name.startswith("cn-") and -1 == i.name.find("-gov-")]
      rgnsb = [i.name  for i in boto.ec2.elb.regions() if not i.name.startswith("cn-") and -1 == i.name.find("-gov-")]
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : regions(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)
    
    self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
    print("\n<Start of Dump EC2/VPC Instances>\n")

    elbs = {}
    for rb in rgnsb:
      try:
        if self.botoprfl[0] != "default":
          connb = boto.ec2.elb.connect_to_region(rb, profile_name = self.botoprfl)
        else:
          connb = boto.ec2.elb.connect_to_region(rb)

        if connb:
          b = connb.get_all_load_balancers()
          for l in b:
            elbs[l.name] = [i.id for i in l.instances]
      except Exception, e:
        serr = ('%s :: dumpInstances(...) : connect_ec2_elb,get_all_load_balancers(...)'
                '%s' %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

    for r in rgns:
      try:
        if self.botoprfl[0] != "default":
          conn = boto.ec2.connect_to_region(r, profile_name = self.botoprfl)
        else:
          conn = boto.ec2.connect_to_region(r)

        if conn:
          v = conn.get_all_volumes()

          for r in conn.get_all_reservations():
            for i in r.instances:
              s = [g.id for g in i.groups]
              t = s.sort()
              r = ",".join(s)

              l = []
              for e in v:
                if e.attach_data.instance_id == i.id:
                  if e.encrypted:
                    enc = "encrypted"
                  else:
                    enc = "unencrypted"
                  l.append("%s=%s@%s:%s" %(e.attach_data.device, e.size, e.type, enc))

              j = []
              for k in elbs:
                if i.id in elbs[k]:
                  j.append(k)

              s = "| ID: %s | PDNS: %s | PVTDNS: %s | ImageID: %s | Tags: %s | Type: %s |\
   State: %s | Key: %s | GRPS: %s | PIP: %s | PVTIP: %s | SNID: %s | VPCID: %s | Monitored: %s|\
   Region: %s | Vols: %s | Elbs: %s"\
                    %(i.id,i.public_dns_name,i.private_dns_name,i.image_id,i.tags.get('Name',''),\
                      i.instance_type,i.state,i.key_name,r,i.ip_address,i.private_ip_address,\
                      i.subnet_id,i.vpc_id,i.monitored,i.region.name,",".join(l),",".join(j) or "")
              self.opygenericroutines.prntLogErrWarnInfo(str(s), 'info', bresume=True)
      except Exception, e:
        serr = ('%s :: dumpInstances(...) : connect_ec2,get_all_volumes,get_all_reservations(...)'
                '%s' %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

    self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
    print("\n<End of Dump EC2/VPC Instances>\n")
   
  def dumpS3Buckets(self):
    '''
      Method to dump S3 buckets info.
    '''
    
    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_s3(profile_name = self.botoprfl)
      else:
        conn = boto.connect_s3()
      if conn:
        print("\n<Start of Dump S3 Buckets>\n")
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        for b in conn.get_all_buckets():
          s = " %s" %b.name
          #print b.get_all_keys()
          self.opygenericroutines.prntLogErrWarnInfo(str(s), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Dump S3 Buckets>\n")
    except Exception, e:
      serr = ('%s :: dumpS3Buckets(...) : connect_s3,get_all_buckets(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)
 
  def dumpSecuritygps(self):
    '''
      Method to dump EC2/VPC security groups info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_ec2(profile_name = self.botoprfl)
      else:
        conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Dump Security Groups>\n")
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        for s in conn.get_all_security_groups():
          sg = " Name: %s , ID: %s , RLS: %s , RLSE: %s" \
               %(s.name,s.id,s.rules,s.rules_egress)
          self.opygenericroutines.prntLogErrWarnInfo(str(sg), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Dump Security Groups>\n")
    except Exception, e:
      serr = ('%s :: dumpSecuritygps(...) : connect_ec2,get_all_security_groups(...), '
              '%s' %(self.sclsnme, str(e)))

  def dumpKeypairs(self):
    '''
      Method to dump Keypairs info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_ec2(profile_name = self.botoprfl)
      else:
        conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Dump Keypairs>\n")
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        for k in conn.get_all_key_pairs():
          kp = " %s" %k.name
          self.opygenericroutines.prntLogErrWarnInfo(str(kp), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Dump Keypairs>\n")
    except Exception, e:
      serr = ('%s :: dumpKeypairs(...) : connect_ec2,get_all_key_pairs(...), '
              '%s' %(self.sclsnme, str(e)))

  def dumpSubnets(self):
    '''
      Method to dump VPC subnets info.
    '''
    try:
      rgns = [i.name  for i in boto.ec2.regions() if not i.name.startswith("cn-") and -1 == i.name.find("-gov-")]
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : regions(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

    self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
    print("\n<Start of Dump VPC Subnets>\n")

    d = {}
    for r in rgns:
      try:
        if self.botoprfl[0] != "default":
          conn = boto.ec2.connect_to_region(r, profile_name = self.botoprfl)
        else:
          conn = boto.ec2.connect_to_region(r)
        if conn:
          for r in conn.get_all_reservations():
            for i in r.instances:
              if i.vpc_id:
                if d.has_key(i.vpc_id):
                  if d[i.vpc_id].has_key(i.subnet_id):
                    d[i.vpc_id][i.subnet_id].append(
                      {
                        "name": i.tags.get("Name","Name"),
                        "type": i.instance_type,
                        "state": i.state,
                        "region": i.region.name,
                        "privateip": i.private_ip_address,
                        "blockdevice": i.block_device_mapping,
                      }
                    )
                  else:
                    d[i.vpc_id][i.subnet_id] = [
                      {
                        "name": i.tags.get("Name","Name"),
                        "type": i.instance_type,
                        "state": i.state,
                        "region": i.region.name,
                        "privateip": i.private_ip_address,
                        "blockdevice": i.block_device_mapping,
                      }
                    ]

                else:
                  d[i.vpc_id] = {
                                i.subnet_id:
                                  [
                                    {
                                      "name": i.tags.get("Name","Name"),
                                      "type": i.instance_type,
                                      "state": i.state,
                                      "region": i.region.name,
                                      "privateip": i.private_ip_address,
                                      "blockdevice": i.block_device_mapping,
                                    }
                                  ]
                              }

      except Exception, e:
        serr = ('%s :: dumpInstances(...) : connect_ec2,get_all_reservations(...), '
                '%s' %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

    c = VPCConnection()
    for v in d:
      print(" %s :" %v)
      for s in d[v]:
        print("  %s :" %s)
        for i in d[v][s]:
          print("   %s" %i)
      print

    #print d.keys()

    self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
    print("\n<End of Dump VPC Subnets>\n")

  def dumpSQSQueues(self):
    '''
      Method to dump SQS queues info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_sqs(profile_name = self.botoprfl)
      else:
        conn = boto.connect_sqs()
      if conn:
        print("\n<Start of Dump SQS Queues>\n")
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        for q in conn.get_all_queues():
          sq = " %s" %q.name
          self.opygenericroutines.prntLogErrWarnInfo(str(sq), 'info', bresume = True)
          self.opygenericroutines.prntLogErrWarnInfo("   Url: %s" % str(q.url), 'info', bresume = True)
          dq = q.get_attributes()
          for a in self.tsqsinfo:
            if a == 'CreatedTimestamp' or a == 'LastModifiedTimestamp':
              sa = "   %s: %s" %(str(a),time.strftime("%a, %d %b %Y %H:%M:%S", time.gmtime(float(dq[a]))))
            else:
              sa = "   %s: %s" %(a, dq[a])
            self.opygenericroutines.prntLogErrWarnInfo(str(sa), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Dump SQS Queues>\n")
    except Exception, e:
      serr = ('%s :: dumpSQSQueues(...) : connect_sqs,get_all_queues(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

  def dumpRedshift(self):
    '''
      Method to dump Redshift clusters info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_redshift(profile_name = self.botoprfl)
      else:
        conn = boto.connect_redshift()
      if conn:
        print("\n<Start of Redshift clusters>\n")
        for c in conn.describe_clusters()['DescribeClustersResponse']['DescribeClustersResult']['Clusters']:
          self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
          for i in self.trsinfo:
            if i == 'ClusterCreateTime':
              sinfo = " %s: %s" %(str(i),time.strftime("%a, %d %b %Y %H:%M:%S", time.gmtime(c[i])))
            else:
              sinfo = " %s: %s" %(str(i),str(c[i]))
            self.opygenericroutines.prntLogErrWarnInfo(sinfo, 'info', bresume = True)
          self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Redshift clusters>\n")
    except Exception, e:
      serr = ('%s :: dumpRedshift(...) : connect_redshift,list_clusters(...).clusters, '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)

  def dumpEMRClusters(self):
    '''
      Method to dump EMR clusters info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_emr(profile_name = self.botoprfl)
      else:
        conn = boto.connect_emr()
      if conn:
        print("\n<Start of EMR clusters>\n")
        print(" Jobflows: %s" %conn.describe_jobflows())
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        for c in conn.list_clusters().clusters:
          ec = " %s" %c
          self.opygenericroutines.prntLogErrWarnInfo(str(ec), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of EMR clusters>\n")
    except Exception, e:
      serr = ('%s :: dumpEMRClusters(...) : connect_emr,list_clusters(...).clusters, '
              '%s' %(self.sclsnme, str(e)))
      prntErrWarnInfo(serr, bresume = True)

  def dumpKinesis(self):
    '''
      Method to dump Kinesis streams info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_kinesis(profile_name = self.botoprfl)
      else:
        conn = boto.connect_kinesis()
      if conn:
        print("\n<Start of Kinesis streams>\n")
        for c in conn.list_streams():
          print(" %s" %c.title())
        print("\n<End of Kinesis streams>\n")
    except Exception, e:
      serr = ('%s :: dumpKinesis(...) : connect_kinesis,list_streams(...), '
              '%s' %(self.sclsnme, str(e)))

  def dumpAmis(self):
    '''
      Method to dump AMIs info.
    '''

    try:
      if self.botoprfl[0] != "default":
        conn = boto.connect_ec2(profile_name = self.botoprfl)
      else:
        conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Dump AMIs>\n")
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        imgs = [i.image_id for r in conn.get_all_reservations() for i in r.instances]
        imgs = list(set(imgs))
        for i in conn.get_all_images(imgs):
          ai = " ID: %s , TAGS: %s , Description: %s , BDM: %s"\
                %(i.id,i.tags,i.description,i.block_device_mapping)
          self.opygenericroutines.prntLogErrWarnInfo(str(ai), 'info', bresume = True)
        self.opygenericroutines.prntLogErrWarnInfo('', 'info', bresume = True)
        print("\n<End of Dump AMIs>\n")
    except Exception, e:
      serr = ('%s :: dumpAmis(...) : connect_ec2,get_all_images(...), '
              '%s' %(self.sclsnme, str(e)))

  def dumpInfo(self):
    '''
      Method to dump the requested info.
    '''

    if self.iflag:
      self.dumpInstances()

    if self.bflag:
      self.dumpS3Buckets()

    if self.sflag:
      self.dumpSecuritygps()

    if self.kflag:
      self.dumpKeypairs()

    if self.uflag:
      self.dumpSubnets()

    if self.qflag:
      self.dumpSQSQueues()

    if self.rflag:
      self.dumpRedshift()

    if self.eflag:
      self.dumpEMRClusters()

    if self.nflag:
      self.dumpKinesis()
    
    if self.mflag:
      self.dumpAmis()

def mainconsole(odumpawsinfo):
  '''
      Main application driver routine for console mode.
  '''

  if odumpawsinfo.parseOptsArgs():
    odumpawsinfo.dumpInfo() 
  else:
    serr = 'mainconsole(...):parseOptsArgs(...) failed.'
    _prntErrWarnInfo(serr, 'err', bresume = True)


if '__main__' == __name__:
  '''
    Routine to run in case file is not imported as a module.
  '''

  odumpawsinfo = DumpAwsInfo()
  mainconsole(odumpawsinfo)

