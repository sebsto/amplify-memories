build:
	sam build --use-container

deploy:
	sam deploy --config-file ./samconfig.toml --config-env dev

logs:
	sam logs --stack-name memories-cognito-triggers

run:
	python src/app.py 

test:
	python -m pytest
