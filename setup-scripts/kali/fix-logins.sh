userdel -r student

for s in a b c d e; do

   username="student${s}"

   echo $username

   useradd -m $username
   echo "$username:5tudent!" | chpasswd

   touch /home/$username/.hushlogin 

   echo "$username ALL=(ALL) NOPASSWD:ALL" | EDITOR='tee -a' visudo
   usermod -a -G sudo $username
   chsh $username -s /bin/zsh

done