all: pgfactory_core wh_nagios pr_grapher
	
pgfactory_core:
	@cd core; \
	$(MAKE) install

wh_nagios: pgfactory_core
	@cd warehouses/wh_nagios; \
	$(MAKE) install

pr_grapher: pgfactory_core
	@cd processes/pr_grapher; \
	$(MAKE) install
