# .PHONY: setup check
# setup:  ## create .env from the template (never overwrites an existing one)
# 	@test -f .env && echo ".env already exists" || (cp .env.example .env && echo "Created .env: put your Gemini key in it")
# check:  ## prove Docker, the papers and (if set) the key work
# 	./run.sh check.py


.PHONY: setup check

setup:  ## create .env from the template (never overwrites an existing one)
	python -c "import os, shutil; shutil.copyfile('.env.example', '.env') if not os.path.exists('.env') else print('.env already exists')"
	python -c "import os; print('Created .env: put your Gemini key in it') if os.path.exists('.env') else None"

check:  ## prove Docker, the papers and (if set) the key work
	run.bat check.py
