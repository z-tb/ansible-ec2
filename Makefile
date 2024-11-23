# Makefile
TF="tofu"

# ANSI color codes
GREEN = \033[32m
RED = \033[31m
RESET = \033[0m

# Set the environment variable (default is "prod")
ENV ?= dev

# Ascii Art Box around header
BOX_TOP := ╔═════════════════════════════════════════════════════════════════
BOX_BOTTOM := ╚═════════════════════════════════════════════════════════════════
BOX_SIDE := ║
BOX_SPACE :=

# info block
HEADER := $(BOX_TOP)\n$(BOX_SIDE) Provisioning environment: $(ENV)\n$(BOX_BOTTOM)

# reconfigure for prod/dev
reconfig:
	@echo "$(if $(filter prod,$(ENV)),$(RED)$(HEADER),$(GREEN)$(HEADER))$(RESET)"
	$(TF) init -reconfigure -var-file=$(ENV).tfvars -backend-config=$(ENV)-backend.conf

# Target: init
init:
	@echo "$(if $(filter prod,$(ENV)),$(RED)$(HEADER),$(GREEN)$(HEADER))$(RESET)"
	$(TF) init -var-file=$(ENV).tfvars -backend-config=$(ENV)-backend.conf

plan:
	@echo "$(if $(filter prod,$(ENV)),$(RED)$(HEADER),$(GREEN)$(HEADER))$(RESET)"
	$(TF) plan -var-file=$(ENV).tfvars

apply:
	@echo "$(if $(filter prod,$(ENV)),$(RED)$(HEADER),$(GREEN)$(HEADER))$(RESET)"
	$(TF) apply -var-file=$(ENV).tfvars

destroy:
	@echo "$(if $(filter prod,$(ENV)),$(RED)$(HEADER),$(GREEN)$(HEADER))$(RESET)"
	$(TF) destroy -var-file=$(ENV).tfvars
# Vim modeline
# vim: syntax=make ts=8 sw=8 noet
