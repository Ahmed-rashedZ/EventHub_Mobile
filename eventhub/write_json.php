<?php
$private_key = "-----BEGIN PRIVATE KEY-----\n" .
"MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDGVzbGKLWNX5ZF\n" .
"/xJXA9aXkrQncshciMjxUfFi+QKv9UcWQBPTvQs7kmXiuNzqCgXWF7u1EFcVa6jT\n" .
"Kn5aW0lY14C+khA+p+oSsgVfH7bw5M48mXPWxEvfYxu5CxsfMcrroHZENcOJBo38\n" .
"B2piSHYMWYqowS5KTyxYhpQvQfI4vTLh2JmeAWtlv4IUX0LVCq/cRvtwHRLcgHTZ\n" .
"ebBaavuzGxjI9oFYIrqQAq7HI1Cyrbx5RohuuTw6KjA9cTd3wbJ0Kn/SCcHM4yEa\n" .
"/bFdU/rhJMAKHXG3Lm0GRu1HK+EqPyAi1oh3mLjC5HYVHWtLWQ+5TOhVqu38Wq6e\n" .
"R3jLOOmJAgMBAAECggEAP0JYy3n3cdg/XyLcEBm+y0g0onJXGkBcSq+WfDkslL93\n" .
"xU55pGpil0T5rwbEGvdIZkDakwTbqY7VYUhn1VzRN39AZkfC26EFpKHX2b+NQybO\n" .
"6oAM9L5V7rE3Cd1TcK8aZ+2dWuME8wK+rVgWI7O1xvmWIn2+zF+VJsUBpVL0tQh+\n" .
"tUWKUCIuKocrk7wAyIirOM3s5S3EdGTUYWYV2a32LeBOCR4fuoj6xkvYO0etz+Am\n" .
"R1sIuHKawqXucHjDNq26HWADH9HCDBQPIh/GIN7Ozvw6yAMIEuOH2E1TrhTrzlut\n" .
"rbUdXvXYbyofF2+TE+NvAc/hp8JDlufcI5yv0gumAwKBgQD4NYFQqf01DA+F6r90\n" .
"XiSBUomoYN0PA2m9HHKyryV2EZViphr5I0z2/14/YB14jIbzXfE4WdErlzbJX3oX\n" .
"DEH1JkAWu+XXJPnBKEWHk9K4HiVHShHeSJIOU4GGFAotS3+KlzdDC3wh+nmR9fQD\n" .
"zo/WBGnz5+FBa2OJXAwpyLguFwKBgQDMkP1W6CrP73+3irt/XVPJRXDB/RKxLr/Q\n" .
"OWGOkfb5tQOfDpelnc3tjskPfGIe62t8MYP2RavimH7OW7Zg+fLRaDitV8y6vX15\n" .
"IFw4KFled7zRgoLA80XQqwESh2Rg5afz1TsvWgguGtEkGFHO3I9h7IDJYkUo5J8Z\n" .
"T9DsRmcJXwKBgQCoxiEXS29sabYIdnYW14j1Er2d67eE5Oo6eCSZ0bSkUxKEELSY\n" .
"oeNMtJpOd7myZcPBqihDC/fKLzlGtpBbKa+T1Z2Ql9WSdIcLS6nzpZWMMptgnUIH\n" .
"JsuByFBzbh75a7Pe9jHSefW/WQTfNiHlkMiHW1r8SbkGddIp7ZgrtVtfowKBgQCV\niUtX0yEwnS9sWQKUqQFNePBjLf8S/EyFBt0Ungi/Ip5CECW0kDVveVfqdQ848PjC\ncWO4i9eJLdZMPOiF3VCt2RTNSghDXa8x8wDWoFAr6TVipZe1OmAHmGmRRN2Qo3Bx\noqbAB31BTqMhUpHCuKIrf/novGg361+N3jWn8hLx2wKBgQDgnv+1e2uMmDHZbV8u\na99mvyTKEkUupqkw/iAuNx70Ut8rafRm/EjtkzlHoBmZSdEsUnp5DpjjCSIhM1jn\nPTqy+7eYvio/d4homaTBZI2Ijg0ZRHXshW4L+x2hZHRCpA80IiZkcDH4AhnKjmRB\n6LqTl8EL1rsKubiou7kMcLLT8A==\n" .
"-----END PRIVATE KEY-----\n";

$data = [
    'type' => 'service_account',
    'project_id' => 'eventhub-bf56e',
    'private_key_id' => 'e590f6ff95e39425b034ee0f3246a41d67a82094',
    'private_key' => $private_key,
    'client_email' => 'firebase-adminsdk-fbsvc@eventhub-bf56e.iam.gserviceaccount.com',
    'client_id' => '109875466409604319982',
    'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
    'token_uri' => 'https://oauth2.googleapis.com/token',
    'auth_provider_x509_cert_url' => 'https://www.googleapis.com/oauth2/v1/certs',
    'client_x509_cert_url' => 'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40eventhub-bf56e.iam.gserviceaccount.com',
    'universe_domain' => 'googleapis.com'
];
file_put_contents('c:/xampp/htdocs/EventHub/EventHub/storage/app/firebase-auth.json', json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "File updated\n";
