### Escuela Colombiana de Ingeniería
### Arquitecturas de Software - ARSW

## Video escalamiento en Azure con Maquinas Virtuales, Sacale Sets y Service Plans
### DAR CLICK A LA IMÁGEN!!!!

[![Demostración del laboratorio paso a paso](https://img.youtube.com/vi/COmMJIr0_eA/maxresdefault.jpg)](https://youtu.be/COmMJIr0_eA)

### Dependencias
* Cree una cuenta gratuita dentro de Azure. Para hacerlo puede guiarse de esta [documentación](https://azure.microsoft.com/es-es/free/students/). Al hacerlo usted contará con $100 USD para gastar durante 12 meses.
Antes de iniciar con el laboratorio, revise la siguiente documentación sobre las [Azure Functions](https://www.c-sharpcorner.com/article/an-overview-of-azure-functions/)

### Parte 0 - Entendiendo el escenario de calidad

Adjunto a este laboratorio usted podrá encontrar una aplicación totalmente desarrollada que tiene como objetivo calcular el enésimo valor de la secuencia de Fibonnaci.

**Escalabilidad**
Cuando un conjunto de usuarios consulta un enésimo número (superior a 1000000) de la secuencia de Fibonacci de forma concurrente y el sistema se encuentra bajo condiciones normales de operación, todas las peticiones deben ser respondidas y el consumo de CPU del sistema no puede superar el 70%.

### Escalabilidad Serverless (Functions)

1. Cree una Function App tal cual como se muestra en las  imagenes.

![](images/part3/part3-function-config.png)

![](images/part3/part3-function-configii.png)

2. Instale la extensión de **Azure Functions** para Visual Studio Code.

![](images/part3/part3-install-extension.png)

3. Despliegue la Function de Fibonacci a Azure usando Visual Studio Code. La primera vez que lo haga se le va a pedir autenticarse, siga las instrucciones.

![](images/part3/part3-deploy-function-1.png)

![](images/part3/part3-deploy-function-2.png)

4. Dirijase al portal de Azure y pruebe la function.

![](images/part3/part3-test-function.png)

5. Modifique la coleción de POSTMAN con NEWMAN de tal forma que pueda enviar 10 peticiones concurrentes. Verifique los resultados y presente un informe.

6. Cree una nueva Function que resuleva el problema de Fibonacci pero esta vez utilice un enfoque recursivo con memoization. Pruebe la función varias veces, después no haga nada por al menos 5 minutos. Pruebe la función de nuevo con los valores anteriores. ¿Cuál es el comportamiento?.

**Preguntas**

* **¿Qué es un Azure Function?**

  Es un pequeño fragmento de código que se ejecuta en la nube de Azure sin que uno tenga que administrar servidores. Se ejecuta cuando ocurre un evento (una petición HTTP, un temporizador, un mensaje en una cola, etc.) y Azure se encarga de escalarlo automáticamente. En este laboratorio, la función de Fibonacci recibe un número por HTTP y devuelve su valor en la secuencia.

* **¿Qué es serverless?**

  Es un modelo de computación en la nube en el que el proveedor (Azure) administra toda la infraestructura: servidores, escalado, sistema operativo y parches. El desarrollador solo se preocupa por escribir y subir el código, y paga únicamente por el tiempo de ejecución. Para el desarrollador es "sin servidores", porque no aprovisiona ni gestiona máquinas.

* **¿Qué es el runtime y que implica seleccionarlo al momento de crear el Function App?**

  El runtime es el lenguaje y la versión con la que se ejecuta el código, por ejemplo Node.js (18, 20, 22...), Python, .NET, Java, etc. Al crear el Function App hay que elegirlo, y eso implica que el código debe estar escrito para ese lenguaje/versión y que la plataforma instalará ese entorno para correrlo. Si se elige mal (por ejemplo una versión vieja o fuera de soporte), la función no arranca o falla, como nos pasó al principio con versiones de Node ya obsoletas.

* **¿Por qué es necesario crear un Storage Account de la mano de un Function App?**

  Porque el host de Functions la usa para guardar información interna: los archivos de la aplicación, el estado y los "leases" del host, las llaves, los logs y el estado de los triggers (temporizadores, colas, etc.). En los planes modernos también se usa para almacenar el paquete de despliegue. Sin una cuenta de almacenamiento el host no puede funcionar ni coordinar la ejecución de las funciones.

* **¿Cuáles son los tipos de planes para un Function App?, ¿En qué se diferencian?, mencione ventajas y desventajas de cada uno de ellos.**

  - **Consumption (clásico):** escala automáticamente, incluso a cero, y se paga por ejecución. *Ventaja:* muy económico y sin administración. *Desventaja:* tiene cold starts y límites de tiempo; además Azure lo está retirando a favor de Flex.
  - **Flex Consumption:** el plan serverless más nuevo y recomendado. *Ventaja:* escalado rápido, menos cold start, instancias más grandes y soporte de red privada. *Desventaja:* es más nuevo y tiene algunas limitaciones de configuración/versiones.
  - **Premium:** mantiene instancias pre-calentadas. *Ventaja:* sin cold start, más CPU/memoria y conexión a VNet. *Desventaja:* es más costoso porque se paga por las instancias.
  - **App Service Plan (dedicado):** usa un plan de App Service normal. *Ventaja:* control total y rendimiento predecible. *Desventaja:* se paga siempre, aunque no haya tráfico.
  - **Container Apps / Kubernetes:** para ejecutar las funciones en contenedores. *Ventaja:* mucho control y portabilidad. *Desventaja:* más complejo de administrar.

* **¿Por qué la memoization falla o no funciona de forma correcta?**

  Porque la memoization guarda los resultados en la memoria del proceso (una variable o un Map), y en serverless esa memoria es efímera y no se comparte. Cuando la instancia se recicla por inactividad (cold start), el caché se pierde y hay que volver a calcular. Además, si la aplicación escala a varias instancias, cada una tiene su propio caché y no se sincronizan. Por eso funciona mientras la instancia está "caliente", pero no es una estrategia confiable; para eso se usa un caché externo como Redis.

* **¿Cómo funciona el sistema de facturación de las Function App?**

  Depende del plan. En **Consumption/Flex** se factura por consumo: número de ejecuciones más el tiempo de ejecución multiplicado por la memoria usada (GB-s), y también se cobran los servicios asociados (Storage, Application Insights). Hay una cuota gratuita mensual (por ejemplo, 1 millón de ejecuciones y 400.000 GB-s en Consumption). En **Premium** o **App Service Plan** se paga por las instancias o la capacidad reservada, aunque no haya tráfico. En resumen: se paga por lo que se consume o por la capacidad reservada, según el plan.

**Informe**
