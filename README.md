# custodian-test
> 테스트용이므로 각자 AWS 환경에서 잘 작동하는지 확인해 주세요.

</br>

### 작동 방법
다음 명령어로 프로젝트를 가져옵니다.
```
git clone https://github.com/ye-nni/custodian-test.git
```
</br>
셸 스크립트의 접근 권한을 변경합니다.

```
chmod +x generate.sh
chmod +x prompt.sh
```
<br>
(선택) Cloud Custodian 정책 실행을 위한 AWS 환경을 배포합니다.

```
terraform init
terraform plan
terraform apply
```

</br>
환경변수 파일(.env)을 각자 환경에 맞게 채워넣어 주세요.(아래는 예시입니다)

```
ACCOUNT_ID=0123456789
AWS_REGION=ap-northeast-2
LAMBDA_ROLE=arn:aws:iam::000123456789:role/custodian-lambda-role
MAILER_ROLE=arn:aws:iam::000123456789:role/custodian-mailer-role
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
QUEUE_URL=https://sqs.ap-northeast-2.amazonaws.com/000123456789/custodian-notify-queue
```

</br>

`.yaml.template` 으로 `.yaml` 파일을 생성합니다.

```
./generate.sh
```

이때, 원하는 리소스만을 선택하여 `.yaml` 정책을 생성할 수 있습니다. `all`을 입력하면 모든 aws 리소스에 대해 정책이 만들어지고 policies 폴더에 저장됩니다.

</br>
</br>

### 수동 조치 방법
`prompt.yaml`은 즉각 수동 조치가 필요할 경우를 대비한 정책 파일입니다.
아래 명령어로 특정 정책이름(CHECKID)에 대해 즉각 조치를 취할 수 있습니다.
```
./prompt.sh <정책이름>
```
또는 모든 정책이름(CHECKID)에 대해 즉각 조치를 취할 수도 있습니다.
```
./prompt.sh all
```
</br>

### 추가할 부분
- policies 폴더에서 정책 람다 배포를 빠르게 할 수 있는 셸 스크립트 작성.
