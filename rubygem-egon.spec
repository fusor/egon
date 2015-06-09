%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name egon

%global foreman_dir /usr/share/foreman
%global foreman_bundlerd_dir %{foreman_dir}/bundler.d
%global foreman_pluginconf_dir %{foreman_dir}/config/settings.plugins.d

%if !("%{?scl}" == "ruby193" || 0%{?rhel} > 6 || 0%{?fedora} > 16)
%global gem_dir /usr/lib/ruby/gems/1.8
%global gem_instdir %{gem_dir}/gems/%{gem_name}-%{version}
%global gem_libdir %{gem_instdir}/lib
%global gem_cache %{gem_dir}/cache/%{gem_name}-%{version}.gem
%global gem_spec %{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%global gem_docdir %{gem_dir}/doc/%{gem_name}-%{version}
%endif

%if "%{?scl}" == "ruby193"
    %global scl_ruby /usr/bin/ruby193-ruby
    %global scl_rake /usr/bin/ruby193-rake
    ### TODO temp disabled for SCL
    %global nodoc 1
%else
    %global scl_ruby /usr/bin/ruby
    %global scl_rake /usr/bin/rake
%endif

Summary: Egon Plugin
Name: %{?scl_prefix}rubygem-%{gem_name}

Version: 0.0.1
Release: 19%{dist}
Group: Development/Ruby
License: Distributable
URL: https://github.com/fusor/egon
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem

%if "%{?scl}" == "ruby193"
Requires: %{?scl_prefix}ruby-wrapper
BuildRequires: %{?scl_prefix}ruby-wrapper
%endif
%if "%{?scl}" == "ruby193" || 0%{?rhel} > 6 || 0%{?fedora} > 16
BuildRequires:  %{?scl_prefix}rubygems-devel
%endif

%if 0%{?fedora} > 19
Requires: %{?scl_prefix}ruby(release) = 2.0.0
BuildRequires: %{?scl_prefix}ruby(release) = 2.0.0
%else
%if "%{?scl}" == "ruby193" || 0%{?rhel} > 6 || 0%{?fedora} > 16
Requires: %{?scl_prefix}ruby(abi) = 1.9.1
BuildRequires: %{?scl_prefix}ruby(abi) = 1.9.1
%else
Requires: ruby(abi) = 1.8
BuildRequires: ruby(abi) = 1.8
%endif
%endif

BuildArch: noarch
Provides: %{?scl_prefix}rubygem(egon) = %{version}

%description
Egon Plugin

%package doc
BuildArch:  noarch
Requires:   %{?scl_prefix}%{pkg_name} = %{version}-%{release}
Summary:    Documentation for rubygem-%{gem_name}

%description doc
This package contains documentation for rubygem-%{gem_name}.

%prep
%setup -n %{pkg_name}-%{version} -q -c -T
mkdir -p .%{gem_dir}
%{?scl:scl enable %{scl} "}
gem install --local --install-dir .%{gem_dir} --bindir .%{_bindir} --force %{SOURCE0}
%{?scl:"}

%build

%install

mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{foreman_bundlerd_dir}
cat <<GEMFILE > %{buildroot}%{foreman_bundlerd_dir}/%{gem_name}.rb
gem '%{gem_name}'
GEMFILE

mkdir -p %{buildroot}%{_bindir}
cp -a .%{_bindir}/* \
        %{buildroot}%{_bindir}/

find %{buildroot}%{gem_instdir}/bin -type f | xargs chmod a+x

mkdir -p %{buildroot}%{foreman_pluginconf_dir}
# TODO: Do we need this guy?
#cp -a %{buildroot}/%{gem_instdir}/config/egon.yaml %{buildroot}%{foreman_pluginconf_dir}/

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root)
%{_bindir}/undercloud-install-vanilla-rhel.rb
%{_bindir}/undercloud-install-satellite.rb
%{_bindir}/undercloud-install-instack-virt.rb
%{gem_instdir}/
%exclude %{gem_cache}
%{gem_spec}
%{foreman_bundlerd_dir}/%{gem_name}.rb
#%{foreman_pluginconf_dir}/egon.yaml

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
