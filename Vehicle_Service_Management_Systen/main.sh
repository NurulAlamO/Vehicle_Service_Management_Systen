#! /bin/bash

declare -a vehicle
declare -a services
declare -a deliveryStatus
declare -a charges

users_file="users.text"
current_user=""
storage=""

#================= Login Panel Function ======================

function register_user() {
    echo -e "\n ============================ User Registration ================================="
    read -p "Enter New Username: " username
    read -sp "Enter New Password: " password
    echo

    if grep -q "^$username:" "$users_file" 2>/dev/null; then
        echo " Username already exists."
    else
        echo "$username:$password" >> "$users_file"
        touch "storage_${username}.text"
        echo " Registration successful. Please login to continue."
    fi
}

function login_user() {
    echo -e "\n =============================== User Login ======================================="
    read -p "Enter Username: " username
    read -sp "Enter Password: " password
    echo

    if grep -q "^$username:$password" "$users_file" 2>/dev/null; then
        echo " Login successful. Welcome, $username!"
        current_user="$username"
        storage="storage_${username}.text"
        menu
    else
        echo " Invalid credentials."
    fi
}

function delete_my_account() {
    echo -e "\n ====================== Delete My Account ========================="
    read -p "Enter Username: " username
    read -sp "Enter Password: " password
    echo

    if grep -q "^$username:$password" "$users_file" 2>/dev/null; then
        read -p "Are you sure you want to delete your account? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            sed -i "/^$username:$password/d" "$users_file"
            rm -f "storage_${username}.text"
            echo "Account deleted successfully."
        else
            echo "Account deletion canceled."
        fi
    else
        echo "Invalid credentials. Cannot delete account."
    fi
}

#===============  Vehicle Service Center Function ================

function register_vehicle() {
    echo -e "\n ============================ Register a New Vehicle ================================="
    read -p "Enter Vehicle Number: " vnum
    read -p "Enter Owner Name: " owner
    read -p "Enter Contact Number: " contact
    read -p "Enter Car Name: " carname

    echo "$vnum | $owner | $contact | $carname | Pending | Not Delivered | 0 | NA | NA" >> "$storage"
    echo "Vehicle Registered Successfully."
}

function add_service_record() {
    echo -e "\n =================================== Service Record Entry ===================================="
    read -p "Enter Vehicle Number: " vnum

    if grep -q "^$vnum" "$storage"; then
        read -p "Enter Service Description: " desc
        read -p "Enter Estimated Charge: " estCharge
        read -p "Enter Service Date (YYYY-MM-DD): " serviceDate

        esc_desc=$(printf '%s\n' "$desc" | sed 's/[\/&]/\\&/g')
        esc_charge=$(printf '%s\n' "$estCharge" | sed 's/[\/&]/\\&/g')
        esc_date=$(printf '%s\n' "$serviceDate" | sed 's/[\/&]/\\&/g')

        sed -i "s/^\($vnum[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*/\1$esc_desc/" "$storage"
        sed -i "s/^\($vnum[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*/\1$esc_charge/" "$storage"
        sed -i "s/^\($vnum[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*/\1$esc_date/" "$storage"

        echo "Service Record Updated."
    else
        echo "Vehicle not found."
    fi
}

function update_delivery_status() {
    echo -e "\n ================================ Update Delivery Status ======================================"
    read -p "Enter Vehicle Number: " vnum
    if grep -q "^$vnum" "$storage"; then
        read -p "Enter Delivery Date (YYYY-MM-DD): " deliveryDate
        esc_dDate=$(printf '%s\n' "$deliveryDate" | sed 's/[\/&]/\\&/g')

        sed -i "/^$vnum/ s/Not Delivered/Delivered/" "$storage"
        sed -i "s/^\($vnum[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*/\1$esc_dDate/" "$storage"

        echo "Delivery Status Updated."
    else
        echo "Vehicle not found."
    fi
}

function view_delivered() {
    echo -e "\n =========================== Delivered Vehicles ============================"
    if [[ -f "$storage" && -s "$storage" ]]; then
        (
            echo "VehicleNo | Owner | Contact | CarName | Service | Delivery | Charge | Service Date | Delivery Date"
            awk -F "|" '$6 ~ /^[[:space:]]*Delivered[[:space:]]*$/' "$storage"
        ) | column -t -s "|"

        total=$(awk -F "|" '$6 ~ /^[[:space:]]*Delivered[[:space:]]*$/{ gsub(/^[ \t]+|[ \t]+$/, "", $7); sum += $7 } END { print sum }' "$storage")
        echo -e "\n Total Charges from Delivered Vehicles: $total"
    else
        echo " No records found."
    fi
}

function view_not_delivered() {
    echo -e "\n ======================= Not Delivered Vehicles ==========================="
    if [[ -f "$storage" && -s "$storage" ]]; then
        (
            echo "VehicleNo | Owner | Contact | CarName | Service | Delivery | Charge | Service Date | Delivery Date"
            awk -F "|" '$6 ~ /Not Delivered/' "$storage"
        ) | column -t -s "|"
    else
        echo "No records found."
    fi
}

function view_all_records() {
    echo -e "\n ======================== All Service Records ==============================="
    if [[ -f "$storage" && -s "$storage" ]]; then
        (
            echo "VehicleNo | Owner | Contact | CarName | Service | Delivery | Charge | Service Date | Delivery Date"
            sort -t "|" -k1 "$storage"
        ) | column -t -s "|"
    else
        echo "No records found."
    fi
}

function delete_vehicle() {
    echo -e "\n =========================== Delete Vehicle Record ============================"
    read -p "Enter Vehicle Number to Delete: " vnum
    if grep -q "^$vnum" "$storage"; then
        sed -i "/^$vnum/d" "$storage"
        echo "Vehicle Record Deleted."
    else
        echo "Vehicle not found."
    fi
}

function clear_storage() {
    > "$storage"
    echo "All records cleared for user: $current_user."
}

function menu() {
    while true; do
        echo -e "\n=========  Vehicle Service Center Menu ========="
        echo "1. Register a Vehicle"
        echo "2. Add Service Record"
        echo "3. Update Delivery Status"
        echo "4. View Delivered Vehicles only"
        echo "5. View Not Delivered Vehicles only"
        echo "6. View All Records"
        echo "7. Delete a Vehicle Record"
        echo "8. Clear All Records"
        echo "9. Logout"
        echo "=================================================="
        read -p "Choose an option [1-9]: " choice

        case $choice in
            1) register_vehicle ;;
            2) add_service_record ;;
            3) update_delivery_status ;;
            4) view_delivered ;;
            5) view_not_delivered ;;
            6) view_all_records ;;
            7) delete_vehicle ;;
            8) clear_storage ;;
            9) echo "Logging out..."; break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

#============= Admin Panel Function ===============

admin_user="admin"
admin_pass="admin123"

function admin_login() {
    echo -e "\n ==================== Admin Login ==========================="
    read -p "Enter Admin Username: " user
    read -sp "Enter Admin Password: " pass
    echo

    if [[ "$user" == "$admin_user" && "$pass" == "$admin_pass" ]]; then
        echo "Admin Login Successful."
        admin_menu
    else
        echo "Invalid admin credentials."
    fi
}

function view_all_users() {
    echo -e "\n Registered Users:"
    if [[ -f "$users_file" && -s "$users_file" ]]; then
        cut -d ":" -f1 "$users_file" | nl
    else
        echo "No users found."
    fi
}

function delete_user_by_admin() {
    read -p "Enter username to delete: " del_user

    if grep -q "^$del_user:" "$users_file"; then
        sed -i "/^$del_user:/d" "$users_file"
        rm -f "storage_${del_user}.text"
        echo "User '$del_user' and their data deleted."
    else
        echo "User not found."
    fi
}

function view_user_records() {
    read -p "Enter username to view records: " uname
    local file="storage_${uname}.text"

    if [[ -f "$file" && -s "$file" ]]; then
        echo -e "\n Records for $uname:"
        (echo "VehicleNo | Owner | Contact | CarName | Service | Delivery | Charge | Service Date | Delivery Date"
         sort "$file") | column -t -s "|"
    else
        echo "No records found for $uname."
    fi
}

function admin_menu() {
    while true; do
        echo -e "\n=========  Admin Panel ========="
        echo "1. View All Users"
        echo "2. Delete a User"
        echo "3. View a User's Records"
        echo "4. Logout"
        echo "=================================="
        read -p "Choose an option [1-4]: " opt

        case $opt in
            1) view_all_users ;;
            2) delete_user_by_admin ;;
            3) view_user_records ;;
            4) echo " Logging out from admin panel..."; break ;;
            *) echo " Invalid option." ;;
        esac
    done
}

function main_menu(){
    while true; do
        echo -e "\n=================== Login Panel =================="
        echo "1.Register"
        echo "2.Login"
        echo "3.Delete My Account"
        echo "4.Admin Login"
        echo "5.Exit"
        echo "============================="
        read -p "Choose an Option (1-5): " opt
        case $opt in
            1) register_user ;;
            2) login_user ;;
            3) delete_my_account ;;
            4) admin_login ;;
            5) echo "Exiting..."; exit ;;
            *) echo "Invalid option." ;;
        esac
    done
}

main_menu

