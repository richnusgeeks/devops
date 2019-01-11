describe package('curl') do
  it { should be_installed }
end

describe package('monit') do
  it { should be_installed }
end
