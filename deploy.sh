#!/bin/bash
echo "# ==========================================="
echo "#  ██████╗ ██████╗ ███████╗███████╗    "
echo "#  ██╔══██╗██╔══██╗██╔════╝██╔════╝    "
echo "#  ██████╔╝██████╔╝█████╗  █████╗      "
echo "#  ██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══╝      "
echo "#  ██║     ██║     ███████╗███████╗    "
echo "#  ╚═╝     ╚═╝     ╚══════╝╚══════╝    "
echo "#  🚀 KODE-SOUL | The Future is Now! 🔥"
echo "#  Automate. Deploy. Dominate."
echo "# ==========================================="

echo "🚀 Bienvenido al script de Terraform"

while true; do
    echo "----------------------------"
    echo "Selecciona una opción:"
    echo "1) Terraform Init y Plan"
    echo "2) Terraform Apply"
    echo "8) 🚨 Terraform Destroy"
    echo "9) Formatear y alinear el código..." 
    echo "5) Salir"
    echo "----------------------------"

    read -p "👉 Ingresa el número de la opción: " opcion

    case $opcion in
        1)
            echo "🔹 Ejecutando terraform init y plan..."
            terraform init -reconfigure && terraform plan
            ;;
        2)
            echo "✅ Aplicando cambios..."
            terraform apply --auto-approve
            ;;
        8)
            echo "🚨 ¡ADVERTENCIA! 🚨"
            read -p "⚠️ ¿Estás seguro de destruir la infraestructura? (8): " confirmacion
            if [ "$confirmacion" = 8 ]; then
                echo "💣 🔥 Destruyendo infraestructura..."
                terraform destroy --auto-approve
            else
                echo "🚫 Operación cancelada."
            fi
            ;;
        5)
            echo "👋 Saliendo del script..."
            exit 0
            ;;
        9)
            echo "Formatear y Lintear el código..." 
            terraform fmt
            terraform validate
            ;;

        *)
            echo "❌ Opción no válida, intenta de nuevo."
            ;;
    esac
done
