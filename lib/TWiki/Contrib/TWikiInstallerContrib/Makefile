
FOSWIKIDEV ?= ~/foswiki
BRANCH ?= DEVELOP
MakeFor ?= foswiki.org-`bin/svnrev.pl`

all : help

TAR_EXCLUDE = --exclude CVS --exclude .svn --exclude "*~" --exclude bak

kernel : 
	[ -e components/kernel ] || mkdir -p components/kernel
	cd $(FOSWIKIDEV)/$(BRANCH)/tools/; FOSWIKI_LIBS=$(FOSWIKIDEV)/$(BRANCH)/BuildContrib/lib/ echo "n" | perl build.pl release; cp $(FOSWIKIDEV)/$(BRANCH)/Foswiki.zip $(FOSWIKIDEV)/$(BRANCH)/FoswikiInstallerContrib/lib/Foswiki/Contrib/FoswikiInstallerContrib/components/kernel/FoswikiKernel$(BRANCH)`$(FOSWIKIDEV)/$(BRANCH)/FoswikiInstallerContrib/lib/Foswiki/Contrib/FoswikiInstallerContrib/bin/svnrev.pl`.zip

$(MakeFor).zip : kernel 
	zip -r $(MakeFor).zip components/extension/ components/kernel/FoswikiKernel$(BRANCH)`bin/svnrev.pl`.*

#	zip -r $(MakeFor).zip components/extension/ components/kernel/TWikiKernel$(BRANCH)*.zip
#	tar --file=$(MakeFor).tar --create $(TAR_EXCLUDE) components/extension/ components/kernel/TWikiKernel$(BRANCH)`bin/svnrev.pl`.*

extensions : 
	cd $(FOSWIKIDEV)/$(BRANCH)/tools/; FOSWIKI_LIBS=$(FOSWIKIDEV)/$(BRANCH)/BuildContrib/lib/ perl build_all_extensions.pl
	[ -e components/extension ] || mkdir -p components/extension
	cp $(FOSWIKIDEV)/$(BRANCH)/*/*.zip components/extension

FoswikiFor : $(MakeFor).zip

distro : foswiki-install extensions $(MakeFor).zip

foswiki-install : remote-install ../FoswikiInstallerContrib.pm
	cp remote-install foswiki-install
	cat ../FoswikiInstallerContrib.pm >>foswiki-install

################################################################################

publish : publish_components

publish_distro :
	scp $(MakeFor).zip $(PUBLISH_TO)/foswiki.org.zip

# NOTE: $(PUBLISH_TO)/foswiki/components/extension has to already exist :(
publish_extensions :
	scp -r $(FOSWIKIDEV)/$(BRANCH)/*/*.zip $(PUBLISH_TO)/foswiki/components/extension

publish_kernels :
	scp -r components/kernel $(PUBLISH_TO)/foswwiki/components

publish_components : publish_distro publish_kernels publish_extensions

################################################################################

clean :
	-rm *.zip
	-rm -rf components/
	-rm install-report.html

################################################################################

print_settings :
	@echo Settings
	@echo ================================================================================
	@echo MakeFor = $(MakeFor)
	@echo FOSWIKIDEV = $(FOSWIKIDEV)
	@echo PUBLISH_TO = $(PUBLISH_TO)

print : print_settings

help : print
	@echo 
	@echo Usage
	@echo ================================================================================
	@echo make [build-options] MakeFor.zip - build and bundle extensions + kernels into .zip
	@echo 
	@echo make distro - download and bundle extensions + kernel
	@echo 
	@echo "make kernel - build FoswikiKernel"
	@echo "make extensions - build extensions (all of plugins, contribs, addons)"
	@echo 
	@echo "make publish - upload distro and extensions + kernels (see below)"
	@echo "make publish_distro - upload distro"
	@echo "make publish_kernels - upload built kernels to $PUBLISH_TO/foswiki/components/kernel/"
	@echo "make publish_extensions - upload built extensions to $PUBLISH_TO/foswiki/components/extension/"
	@echo 
	@echo "make foswiki-install - builds the installation webscript"
	@echo 
	@echo ================================================================================
	@echo build-options:
	@echo   MakeFor - distribution name
