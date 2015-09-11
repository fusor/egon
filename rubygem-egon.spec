%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name egon

%global foreman_dir /usr/share/foreman
%global foreman_bundlerd_dir %{foreman_dir}/bundler.d

Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.4.2
Release: 7%{?dist}
Summary: A library on top of Fog that encapsulates TripleO deployment operations
Group: Development/Languages
License: GPL-3.0+
URL: https://github.com/fusor/egon
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
BuildRequires: %{?scl_prefix}rubygems-devel
BuildRequires: %{?scl_prefix}ruby
BuildRequires: %{?scl_prefix}rubygem(fog) => 1.31.0
BuildRequires: %{?scl_prefix}rubygem(net-ssh) => 2.9.2
BuildRequires: %{?scl_prefix}rubygem(net-ssh) < 2.10
BuildArch: noarch

%description
A library on top of Fog that encapsulates TripleO deployment operations.

%package doc
Summary: Documentation for %{pkg_name}
Group: Documentation
Requires: %{?scl_prefix}%{pkg_name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{pkg_name}.

%prep
%{?scl:scl enable %{scl} - << \EOF}
gem unpack %{SOURCE0}
%{?scl:EOF}

%setup -q -D -T -n  %{gem_name}-%{version}

%{?scl:scl enable %{scl} - << \EOF}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec
%{?scl:EOF}

%build
# Create the gem as gem install only works on a gem file
%{?scl:scl enable %{scl} - << \EOF}
gem build %{gem_name}.gemspec
%{?scl:EOF}

%{?scl:scl enable %{scl} - << \EOF}
gem install %{gem_name}-%{version}.gem --local --install-dir .%{gem_dir}
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
mkdir .%{_bindir}
mv .%{gem_dir}/bin/* \
        .%{_bindir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{foreman_bundlerd_dir}
cat <<GEMFILE > %{buildroot}%{foreman_bundlerd_dir}/%{gem_name}.rb
gem '%{gem_name}'
GEMFILE

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
%license %{gem_instdir}/LICENSE
%{gem_instdir}/bin
%{gem_libdir}
%{gem_instdir}/rubygem-egon.spec
%exclude %{gem_cache}
%{gem_spec}
%{foreman_bundlerd_dir}/%{gem_name}.rb

%files doc
%doc %{gem_docdir}
%{gem_instdir}/Gemfile
%doc %{gem_instdir}/README.md
%{gem_instdir}/Rakefile
%{gem_instdir}/egon.gemspec
%{gem_instdir}/test

%changelog
* Thu Sep 10 2015 Jason Montleon <jmontleo@redhat.com> 0.4.2-7
- gempsec and rpm spec cleanup (jmontleo@redhat.com)

* Thu Sep 10 2015 Jason Montleon <jmontleo@redhat.com> 0.4.2-6
- remove dev require (jmontleo@redhat.com)

* Thu Sep 10 2015 Jason Montleon <jmontleo@redhat.com> 0.4.2-5
- Allow newer version of fog 

* Wed Sep 09 2015 Jason Montleon <jmontleo@redhat.com> 0.4.2-4
- remove bad require (jmontleo@redhat.com)

* Wed Sep 09 2015 Jason Montleon <jmontleo@redhat.com> 0.4.2-3
- Egon RPM compatible with SCL and Foreman (jrist@redhat.com)
- Egon RPM compatible with SCL (jrist@redhat.com)

* Mon Aug 31 2015 jrist <jrist@redhat.com> - 0.4.1-1
- Initial package
