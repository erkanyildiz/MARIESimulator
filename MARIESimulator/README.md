#MARIE
MARIE (Machine Architecture that is Really Intuitive and Easy) bilgisayar organizasyonu ve tasarımı konusunda özellikle öğrenciler için düşünülmüş basit ve kolay anlaşılır bir sanal bilgisayar mimarisidir. 

#MARIE Simülatörü 
MARIE simülatörü Objective-C ile iPad uygulaması olarak yazılmış olup, arayüzü aşağıdaki görseldeki gibidir.

#Arayüz Açıkamaları     
Simülatörün arayüzünde MARIE kodlarının girildiği SOURCE, bellek adres ve içeriğinin görüntülendiği RAM, koddaki etiketlerin görüntülendiği LABELS ve register içeriklerinin görüntülendiği REGISTERS alanları bulunmaktadır. Bu alanlara ek olarak LOAD, RUN, STEP işlemlerinin yapıldığı kontrol butonları ve örnek kodların yüklendiği EXAMPLE butonları bulunmaktadır.

SOURCE alanına kodlar elle girilebildiği gibi EXAMPLE butonlarından biri ile hazır programlar da yüklenebilir. 

LOAD butonu SOURCE alanındaki MARIE kodunu işleyerek LABEL’ları tespit edip RAM alanını komutlara ve adreslere uygun şekilde doldurur. 

RUN butonu LOAD butonu ile çalıştırılmaya hazır hale gelen komutları otomatik olarak çalıştırmaya yarar. HALT komutu görülene kadar simülatör komutları işlemeye ve değişiklikleri RAM ve REGISTERS alanına anında yansıtmaya devam eder. 

STEP butonu komutların tek tek işlenmesini sağlar. 

[210-22F] butonu 2. Örnek kod için gerekli olan bellekte 210-22F arasını rastgele sayılarla doldurmaktadır. 

[350-36F] butonu 3. Örnek kod için gerekli olan bellekte 350-36F arasını rastgele sayılarla doldurmaktadır.      

INREG textfield’ı INPUT komutu için kullanılmaktadır. 