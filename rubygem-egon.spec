%global gem_name egon

Name: rubygem-%{gem_name}
Version: 0.4.1
Release: 1%{?dist}
Summary: A library on top of Fog that encapsulates TripleO deployment operations
Group: Development/Languages
License: GPL-3.0+
URL: https://github.com/fusor/egon
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
BuildRequires: ruby(release)
BuildRequires: rubygems-devel
BuildRequires: ruby
BuildRequires: rubygem(fog) => 1.31.0
BuildRequires: rubygem(fog) < 1.32
BuildRequires: rubygem(net-ssh) => 2.9.2
BuildRequires: rubygem(net-ssh) < 2.10
BuildRequires: rubygem(rspec) => 3.2.0
BuildRequires: rubygem(rspec) < 3.3
BuildArch: noarch

%description
A library on top of Fog that encapsulates TripleO deployment operations.


%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}.

%prep
gem unpack %{SOURCE0}

%setup -q -D -T -n  %{gem_name}-%{version}

gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/


mkdir -p %{buildroot}%{_bindir}
cp -pa .%{_bindir}/* \
        %{buildroot}%{_bindir}/

find %{buildroot}%{gem_instdir}/bin -type f | xargs chmod a+x

# Run the test suite
%check
pushd .%{gem_instdir}

popd

%files
%dir %{gem_instdir}
%{_bindir}/undercloud-install-local.rb
%{_bindir}/undercloud-install-satellite.rb
%{_bindir}/undercloud-install-vanilla-rhel.rb
%exclude %{gem_instdir}/.gitignore
%{gem_instdir}/.ruby-version
%license %{gem_instdir}/LICENSE
%{gem_instdir}/bin
%{gem_libdir}
%{gem_instdir}/rubygem-egon.spec
%exclude %{gem_cache}
%{gem_spec}

%files doc
%doc %{gem_docdir}
%{gem_instdir}/Gemfile
%doc %{gem_instdir}/README.md
%{gem_instdir}/Rakefile
%{gem_instdir}/egon.gemspec
%{gem_instdir}/test

%changelog
* Mon Aug 31 2015 jrist <jrist@redhat.com> - 0.4.1-1
- Initial package
