[Unit]
Description=kijani

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=4096
Restart=always
RestartSec=5s
StandardOutput=append:/home/ubuntu/kijani-worker.log
StandardError=append:/home/ubuntu/kijan-worker.log
ExecStart=/home/ubuntu/pocketbase serve

[Install]
WantedBy = multi-user.target

~ systemctl enable kijani.service
~ systemctl start kijani