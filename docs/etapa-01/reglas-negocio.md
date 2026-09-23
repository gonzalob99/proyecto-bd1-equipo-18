# Reglas de Negocio

**RN.01. Registro de clientes.**
Todo cliente que desee realizar una compra debe estar registrado como cliente del negocio, conservándose sus datos identificatorios y de contacto.

**RN.02. Identificación única del cliente.**
Cada cliente debe poder distinguirse de los demás de manera unívoca. El correo electrónico utilizado para el registro no puede estar asociado a más de un cliente.

**RN.03. Gestión de productos.**
Cada producto comercializado debe contar con la información necesaria para identificarlo y describirlo, incluyendo como mínimo su nombre, descripción, precio y disponibilidad.

**RN.04. Stock por talle.**
La disponibilidad de una prenda se controla según su talle. Un mismo producto puede tener diferentes cantidades disponibles para distintos talles, y dichas cantidades deben considerarse de forma independiente.

**RN.05. Control de stock en las compras.**
Una compra sólo puede confirmarse cuando existe stock suficiente para todos los productos y talles incluidos en ella.

**RN.06. Actualización del stock.**
Una vez confirmada una compra, el stock disponible debe disminuir según las cantidades efectivamente adquiridas.

**RN.07. Relación entre clientes y compras.**
Un cliente puede realizar múltiples compras, pero cada compra debe corresponder a un único cliente.

**RN.08. Composición de una compra.**
Toda compra confirmada debe contener al menos un producto.

**RN.09. Precio unitario histórico.**
Cada producto incluido en una compra debe conservar el precio unitario vigente al momento de realizarse la operación. Una modificación posterior del precio actual de un producto no debe afectar el precio unitario ya registrado en compras anteriores.

**RN.10. Método de pago.**
Toda compra confirmada debe registrar el método de pago utilizado para efectuar la operación. Un mismo método de pago puede ser reutilizado en múltiples compras.

**RN.11. Fecha de la compra.**
Toda compra confirmada debe registrar la fecha en la que se realizó la operación.

**RN.12. Conservación del historial de ventas.**
Las ventas realizadas deben conservarse como información histórica del negocio. Los cambios posteriores en los datos actuales de los productos (más allá del precio, ya cubierto en _RN.09_) no deben alterar la información registrada de ventas anteriores.

**RN.13. Acceso según responsabilidades.**
La gestión de productos, stock y la consulta de información administrativa corresponde al personal autorizado, mientras que las operaciones de compra y administración de los datos propios corresponden a los clientes registrados.
