
pgfactory_core:
	@cd core; \
	$(MAKE) install

wh_nagios: pgfactory_core
	@cd warehouses/wh_nagios; \
	$(MAKE) install
