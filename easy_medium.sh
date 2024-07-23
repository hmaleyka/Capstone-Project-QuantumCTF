#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Function to set up user with specific home directory permissions
setup_user() {
    local username=$1
    local password=$2

    # Create user with home directory and specified shell
    useradd -m -s /bin/bash $username

    # Set user password
    echo "$username:$password" | chpasswd

    # Restrict home directory permissions to user only
    chmod 700 /home/$username
    chown $username:$username /home/$username

    # Ensure user starts in their home directory on login
    echo "cd ~" >> /home/$username/.bashrc
    chown $username:$username /home/$username/.bashrc
}

# Static passwords
ronaldo_password="flag{th1spassword_of_ronaldo}"
wanda_password="flag_crurypassword_987654"
bob_password="flag_bobpassword_123456"
jeff_password="flag_jeffpassword_654321"
curry_password="flag_currypassword_987654"
harry_password="flag_harrypassword_154354"
lewandowski_password="flag{password_of_user_called_lewandowski_654321}"

# Set up users
setup_user ronaldo "$ronaldo_password"
setup_user wanda "$wanda_password"
setup_user bob "$bob_password"
setup_user jeff "$jeff_password"
setup_user curry "$curry_password"
setup_user harry "$harry_password"
setup_user lewandowski "$lewandowski_password"

# Install steghide for Ronaldo
apt-get update
apt-get install -y steghide
chown root:root /usr/bin/steghide
chmod 4755 /usr/bin/steghide

# Download and install exiftool for Lewandowski
apt-get install -y exiftool
chown root:root /usr/bin/exiftool
chmod 4755 /usr/bin/exiftool

# Download images for Ronaldo and Lewandowski
IMAGE_URL_1="https://i.ibb.co/PrWMPHC/goat.jpg"
IMAGE_URL_2="https://i.ibb.co/sQ7hGWT/image.jpg"
IMAGE_NAME_1="goat.jpg"
IMAGE_NAME_2="image.jpg"

# Download image 1 to Ronaldo's home directory
sudo -u ronaldo wget $IMAGE_URL_1 -O /home/ronaldo/$IMAGE_NAME_1

# Download image 2 to Lewandowski's home directory
sudo -u lewandowski wget $IMAGE_URL_2 -O /home/lewandowski/$IMAGE_NAME_2

# Create the nested archives for bob's CTF
su - bob -c "mkdir -p /home/bob/ctf"
su - bob -c "echo '$jeff_password' > /home/bob/ctf/jeff_password.txt"

# Fixed nesting of archives
su - bob -c "tar -cvf /home/bob/ctf/level1.tar -C /home/bob/ctf jeff_password.txt"
su - bob -c "gzip /home/bob/ctf/level1.tar"
su - bob -c "bzip2 /home/bob/ctf/level1.tar.gz"
su - bob -c "tar -cvf /home/bob/ctf/.level2.tar.bz2 -C /home/bob/ctf level1.tar.gz.bz2"
su - bob -c "gzip /home/bob/ctf/.level2.tar.bz2"
su - bob -c "tar -cvf /home/bob/ctf/level3.tar.gz -C /home/bob/ctf .level2.tar.bz2.gz"
su - bob -c "bzip2 /home/bob/ctf/level3.tar.gz"
su - bob -c "tar -cvf /home/bob/ctf/level4.tar.bz2 -C /home/bob/ctf level3.tar.gz.bz2"
su - bob -c "gzip /home/bob/ctf/level4.tar.bz2"
su - bob -c "tar -cvf /home/bob/ctf/.level5.tar.gz -C /home/bob/ctf level4.tar.bz2.gz"

# Clean up intermediate files
su - bob -c "rm /home/bob/ctf/jeff_password.txt /home/bob/ctf/level1.tar.gz.bz2 /home/bob/ctf/.level2.tar.bz2.gz /home/bob/ctf/level3.tar.gz.bz2 /home/bob/ctf/level4.tar.bz2.gz"

# Create curry's password in reverse and ROT28 (equivalent to ROT2)
reversed_curry_password=$(echo "$curry_password" | rev | tr 'A-Za-z' 'C-ZA-Bc-za-b')

# Place curry's password in a file accessible by jeff
su - jeff -c "echo '$reversed_curry_password' > /home/jeff/' '"

# Create 40 directories in Curry's home directory, each with 10 files
hash="ZmxhZ19oYXJyeXBhc3N3b3JkXzE1NDM1NAo="
curry_home="/home/curry"
num_dirs=40
num_files_per_dir=10
file_content="This is a dummy content to make all files the same size."
hash_placed=false

for i in $(seq 1 $num_dirs); do
    dir_path="$curry_home/maze/dir$i"
    su - curry -c "mkdir -p $dir_path"
    for j in $(seq 1 $num_files_per_dir); do
        file_path="$dir_path/file$j"
        if [ "$hash_placed" = false ]; then
            echo "$hash" > /tmp/tempfile
            hash_placed=true
        else
            echo "$file_content" > /tmp/tempfile
        fi
        # Adjust file size to match the largest file
        dd if=/tmp/tempfile of="$file_path" bs=1K count=1 &> /dev/null
    done
done

# Clean up the temporary file
rm /tmp/tempfile

# Create user 'harry' if not already exists
if ! id -u harry >/dev/null 2>&1; then
    sudo useradd -m harry
    echo "User 'harry' created."
else
    echo "User 'harry' already exists."
fi

# Switch to user 'harry'
sudo -u harry bash <<'EOF'
    # Directory and file setup
    HOME_DIR="/home/harry"
    DATA_FILE="$HOME_DIR/data.txt"

    # Function to generate a random string of given length
    generate_random_string() {
        local length=$1
        tr -dc 'a-zA-Z0-9' </dev/urandom | head -c $length
    }

    # Array of word lengths (20-30 characters)
    word_lengths=(20 21 22 23 24 25 26 27 28 29 30)

    # Function to shuffle an array
    shuffle_array() {
        local array=("$@")
        local shuffled_array=()
        local random_index
        while [ ${#array[@]} -gt 0 ]; do
            random_index=$(( RANDOM % ${#array[@]} ))
            shuffled_array+=("${array[$random_index]}")
            unset 'array[$random_index]'
            array=("${array[@]}")
        done
        echo "${shuffled_array[@]}"
    }

    # Create an array to hold the base64 encoded words
    encoded_words=()

    # Calculate how many unique words we need to generate (499 words plus the flag, so 249 pairs)
    unique_word_count=$(( (500 - 1) / 2 ))

    # Generate and encode each random word, ensuring each is duplicated
    for ((i = 0; i < unique_word_count; i++)); do
        length="${word_lengths[$((i % ${#word_lengths[@]}))]}"
        random_word=$(generate_random_string "$length")
        encoded_word=$(echo "$random_word" | base64)
        encoded_words+=("$encoded_word" "$encoded_word")
    done

    # Add the unique word flag{th1spassword_of_ronaldo} encoded in base64 at a random position
    flag="flag{th1spassword_of_ronaldo}"
    encoded_flag=$(echo "$flag" | base64)
    flag_position=$(( RANDOM % (500 - 1) ))
    encoded_words=("${encoded_words[@]:0:$flag_position}" "$encoded_flag" "${encoded_words[@]:$flag_position}")

    # Shuffle the array of encoded words
    shuffled_encoded_words=$(shuffle_array "${encoded_words[@]}")

    # Write the shuffled encoded words to data.txt
    > "$DATA_FILE"
    for word in ${shuffled_encoded_words[@]}; do
        echo "$word" >> "$DATA_FILE"
    done

    # Inform the user that the file has been created
    echo "The file 'data.txt' has been created in your home directory with 500 base64-encoded words in random order, including the unique word flag{th1spassword_of_ronaldo} hidden somewhere inside."
EOF

# Final message
echo "Setup complete."
