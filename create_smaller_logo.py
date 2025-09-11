from PIL import Image
import os

def create_smaller_logo():
    # Ruta del logo original
    input_path = "assets/icons/padelcenterx4transparent.png"
    output_path = "assets/icons/padelcenter_foreground_small.png"
    
    try:
        # Abrir la imagen original
        img = Image.open(input_path)
        
        # Obtener dimensiones originales
        width, height = img.size
        
        # Crear una nueva imagen más grande con fondo transparente
        # Para que el logo se vea más pequeño dentro del área del icono
        new_size = max(width, height) * 2  # Hacer el canvas el doble de grande
        new_img = Image.new('RGBA', (new_size, new_size), (0, 0, 0, 0))
        
        # Calcular posición para centrar el logo original (más pequeño)
        x = (new_size - width) // 2
        y = (new_size - height) // 2
        
        # Pegar el logo original en el centro
        new_img.paste(img, (x, y), img)
        
        # Guardar la nueva imagen
        new_img.save(output_path, 'PNG')
        print(f"Logo más pequeño creado: {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_smaller_logo()
