import pytest

def test_os(host):
  os = host.system_info
  assert os.type.lower() == 'linux'

def test_passwd_file(host):
  passwd = host.file("/etc/passwd")
  assert passwd.contains("root")
  assert passwd.user == "root"
  assert passwd.group == "root"
  assert passwd.mode == 0o644

@pytest.mark.parametrize("name,version", [
  ("openssh-server", ""),
  ("docker", "19"),
])
def test_package_installed(host, name, version):
  pkg = host.package(name)
  assert pkg.is_installed
  assert bool(pkg.version.find(version)+1)

@pytest.mark.parametrize("name", [
  "sshd",
  "containerd",
  "java",
])
def test_process_running(host, name):
  prcs = host.process.filter(user="root", comm=name)
  assert prcs

@pytest.mark.parametrize("name", [
  "sshd",
  "docker",
])
def test_service_running_and_enabled(host, name):
  svc = host.service(name)
  assert svc.is_running
  assert svc.is_enabled

@pytest.mark.parametrize("port", [
  "22",
  "2181",
  "9092",
])
def test_port_listening_ipv46(host, port):
  sckt = host.socket("tcp://%s" %port)
  assert sckt.is_listening
