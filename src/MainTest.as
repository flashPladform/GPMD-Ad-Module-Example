package  
{
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Rectangle;
    import flash.utils.Timer;
    import ru.ngl.utils.Console;
    import ru.pladform.AdCreator;
    import ru.pladform.AdWrapper;
    import ru.pladform.event.AdEvent;
    import ru.pladform.event.PladformAdModuleEvent;
    import ru.pladform.IViewInfo;
    /**
     * Пример раобты с библиотекой рекламного модуля v.2.0 lib/pladform_GPMD.swc. В данном примере раскрываются основные принципы работы с рекламой: загрузка и воспроизведение, изменение размеров. Данный пример не является пособием взаимодействия рекламы и видео
     * @author Alexander Semikolenov
     */
    public class MainTest extends MovieClip
    {
        //ссылка на преролл
        static private var PREROLL_PATH     :String = "http://demo.tremorvideo.com/proddev/vast/vast2RegularLinear.xml#sthash.IZHJY6ne.dpuf"
        //ссылка на постролл
        static private var POSTROLL_PATH    :String = "http://ad3.liverail.com/?LR_PUBLISHER_ID=1331&LR_CAMPAIGN_ID=229&LR_SCHEMA=vast2"
        //ссылка на мидролл
        static private var MIDROLL_PATH     :String = "http://demo.tremorvideo.com/proddev/vast/vast_wrapper_linear_2.xml"
        //ссылка на оверлей
        static private var OVERLAY_PATH     :String = "http://ad3.liverail.com/?LR_PUBLISHER_ID=1331&LR_CAMPAIGN_ID=228&LR_SCHEMA=vast2"
        
        
        public var someVideo            :MovieClip      //Эмуляция видео
        public var btPlayPause          :Bt             //Кнопка воспроизведения/паузы
        public var btVolume             :Bt             //Кнопка управления звуком
        
        private var adWrapperPreroll    :AdWrapper;     //реклама преролла
        private var adWrapperPostroll   :AdWrapper;     //реклама постролла
        private var adWrapperMidroll    :AdWrapper;     //реклама мидролла
        private var adWrapperOverlay    :AdWrapper;     //реклама оверлея
        private var currentWrapper      :AdWrapper;     //текущая реклама
        private var adCreator           :AdCreator;     //рекламный креатор
        private var isVideoMostStopped  :Boolean;       //флаг информирующий о том что видео должно остановиться
        private var isPrerollComplete   :Boolean;       //флаг завершения преролла
        private var isMidrollShowed     :Boolean;       //флаг завершения мидролла
        private var resizePoint         :Sprite;        //спрайт - точка изменения размеров рекламы
        private var overLayTimer        :Timer;         //таймер для показа оверлея
        
        private var overlayStartTime    :uint = 1000;   //Время запуска оверлея
        public function MainTest() 
        {
            if (stage)
            {
                addToStageHandler(null)
            }
            else
            {
                addEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
            }
        }
        
        // STATIC METHODS
        
        // ACCESSORS
        
        // PUBLIC METHODS
        
        // PROTECTED METHODS
        
        // EVENT HANDLERS
        /**
         * Событие обработки таймера для показа оверлея
         * @param    e
         */
        private function overLayTimerHandler(e:TimerEvent):void 
        {
            showOverlay()
        }
        /**
         * Перетаскивание теочки ресайза
         * @param    e
         */
        private function mouseResizePointHandler(e:MouseEvent):void 
        {
            if (e.type == MouseEvent.MOUSE_DOWN)
            {
                resizePoint.startDrag(false, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
                resizePoint.addEventListener(Event.ENTER_FRAME, resizeHandler)
            }
            else
            {
                resizePoint.stopDrag();
                resizePoint.removeEventListener(Event.ENTER_FRAME, resizeHandler)
                resizeHandler(null)
            }
        }
        /**
         * Ищем позицию для мидролла, половину видео
         * @param    e
         */
        private function oefHandler(e:Event):void 
        {
            //мидролл должен быть еще не показан и наша симуляция должна проиграться на половину
            if (!isMidrollShowed && someVideo.currentFrame >= .5 * someVideo.totalFrames)
            {
                //отмечаем что мидролл мы уже пытались отобразить
                isMidrollShowed     = true;
                removeEventListener(Event.ENTER_FRAME, oefHandler)
                if (!adCreator.isReady) return;
                //Создаем мидролл - объект AdWrapper, отвечающий за показ рекламы
                adWrapperMidroll    = adCreator.create();
                //подписываем его на все рекламные события
                initHandlers(adWrapperMidroll)
                //Инициируем загрузку рекламного креатива
                adWrapperMidroll.load(MIDROLL_PATH);
            }
            
        }
        /**
         * Изменение размеров области отображения рекламного креатива
         * @param    e
         */
        private function resizeHandler(e:Event):void 
        {
            someVideo.width     = resizePoint.x;
            someVideo.height    = resizePoint.y;
            btPlayPause.x       = 10;
            btPlayPause.y       = someVideo.height + 5;
            btVolume.x          = btPlayPause.x+btPlayPause.width+10;
            btVolume.y          = btPlayPause.y;
            //если есть отображаемый креатив
            if (currentWrapper) 
            {
                if (currentWrapper.adLinear)
                {
                    //ресайз для линейного креатвиа
                    currentWrapper.viewInfo.roLinear.update(0, 0, someVideo.width, someVideo.height);
                }
                else
                {
                    //слот нелинейного отображается в рамках линейного поэтому при необходимости поднять его над контроллами плеера, нужно изменить размеры линейного креатива
                    currentWrapper.viewInfo.roLinear.update(0, 0, someVideo.width, someVideo.height-40);
                }
            }
        }
        /**
         * Обработка кликов по кнопке уровня громкости
         * @param    e
         */
        private function btVolumeClickHandler(e:MouseEvent):void 
        {
            var arVolome    :Array  = [0, .25, .5, .75, 1];    //массив допустимых значений уровня громкости
            var num         :Number = Number(btVolume.text)    
            var index       :int    = arVolome.indexOf(num);
            //переключаем уровень громкости на следующий из массива
            if (index == -1)
            {
                var length:int = arVolome.length;
                for (var i:int = length-1; i > 0; i--) 
                {
                    if (num < arVolome[i])
                    {
                        index = i;
                    }
                }
            }
            
            index++;
            
            if (index > arVolome.length - 1)
            {
                index = 0;
            }
            btVolume.text = String(arVolome[index]);
            if (adWrapperPreroll)
            {
                adWrapperPreroll.adVolume    = Number(btVolume.text);
            }
            if (adWrapperMidroll)
            {
                adWrapperMidroll.adVolume    = Number(btVolume.text);
            }
            if (adWrapperPostroll)
            {
                adWrapperPostroll.adVolume   = Number(btVolume.text);
            }
        }
        
        /**
         * Обработка событий рекламы
         * @param    e
         */
        private function vpaidHandler(e:AdEvent):void 
        {
            var target:AdWrapper = AdWrapper(e.currentTarget);
            switch(e.type)
            {
                case AdEvent.AdRemainingTimeChange:
                {
                    var str:String = "{"
                    var arP:Array = [];
                    for (var val:String in e.data) 
                    {
                        arP.push(val + ": " + e.data[val]);
                    }
                    str += arP.join(", ") + "}";
                    Console.log("AdRemainingTimeChange: ",str, target.adRemainingTime)
                    break;
                }
                case AdEvent.AdVolumeChange:
                {
                    btVolume.text = String(target.adVolume);
                    break;
                }
                case AdEvent.AdLoaded:
                {
                    //После получения информации о загрузке рекламного креатива, выставляем его размер
                    target.viewInfo.roLinear.update(0, 0, someVideo.width, someVideo.height);
                    //В целях тестового показа, если помимо текущего креатива показывается какой-то другой, другой креатив завершаем
                    if (currentWrapper && currentWrapper != target) 
                    {
                        currentWrapper.stopAllAd();
                    }
                    currentWrapper    = target;
                    //После получения информации о том что креатив загружен, необходимо добавить его на сцену, если он не был добавлен ранее.
                    addChild(target)
                    break;
                }
                case AdEvent.AdStarted:
                {
                    //При начале воспроизведения можно установить уровень громкости звука
                    target.adVolume = Number(btVolume.text);
                    //Так же нужно покатавить видео на паузу
                    if (target == adWrapperMidroll)
                    {
                        pauseVideo();
                    }
                    //Если возникает необходимость, то можно изменить расположение UI контроллов модуля. Однако если это UI контроллы рекламного креатива, то их позиция не изменится.
                    if(target == adWrapperPreroll) currentWrapper.viewInfo.roLinearIndentionUI.height    = 15;
                    resizeHandler(null)
                    break
                }
                case AdEvent.AdClickThru:
                {
                    //При клике на креатив, нужно посатвить на паузу, однако не всегда это возможно, если невозможно креатив будет завершен
                    isVideoMostStopped = true;
                    target.pauseAd();
                    break;
                }
                case AdEvent.AdPaused:
                {
                    //Снимаем метку завиящую от паузы
                    isVideoMostStopped = false;
                    break;
                }
                case AdEvent.AdError:
                {
                    Console.log("ERROR:",e.data.message)
                }
                case AdEvent.AllAdStopped:
                {
                    //Прии окончании вопроизведения или ошибке производим обработку завершения рекламы 
                    if (target.parent) removeChild(target)
                    currentWrapper = null;
                    if (target == adWrapperPreroll)
                    {
                        adWrapperPreroll    = null;
                        prerollComplete()
                    }
                    else if (target == adWrapperPostroll)
                    {
                        adWrapperPostroll    = null;
                        postrollComplete()
                    }
                    
                    else if (target == adWrapperMidroll)
                    {
                        adWrapperMidroll    = null;
                        modrollComplete()
                    }
                    break;
                }
            }
        }
        /**
         * Обработка событий ошибки или загрузки рекламного модуля
         * @param    e
         */
        private function adModuleHandler(e:PladformAdModuleEvent):void 
        {
            //Здесь можно обработать различным образом ошибку и успешную загрузку. Важно, что после загрузки рекламного модуля состояние успешной загрузки можно получить через adCreator.isReady
            Console.log("adCreator.isReady:", adCreator.isReady);
        }
        /**
         * Завершенеи воспроизведения симуляции видео
         * @param    e
         */
        private function completeVideoHandler(e:Event):void 
        {
            if (adCreator.isReady)
            {
                //После завершения видео, если креатор готов, то показываем постролл 
                showPostroll()
            }
            else
            {
                //ставим нашу симуляцию на паузу
                pauseVideo();
            }
        }
        /**
         * Клик по кнопке воспроизведения
         * @param    e
         */
        private function playPauseClickHandler(e:MouseEvent):void 
        {
            //Если показываем преролл, то не делаем ничего
            if (adWrapperPreroll) return; 
            //Ориентироваться в статусе воспроизведения будем по надписи на кнопке 
            //"play" - видео на паузе, "pause" - видео воспроизводится, т.к. кнопка отображает состояние на которое можно переключиться
            if (btPlayPause.text == "play")
            {
                //Если видео можем воспроизвести
                if (adCreator.isReady && someVideo.currentFrame == 1 && !isPrerollComplete)
                {
                    //Если можем  воспроизвести рекламу, видео еще в самом начале и преролл еще не завершен, значит можно показать преролл
                    showPreroll()
                }
                else
                {
                    //в противном случае запускаем воспроизведение видео
                    playVideo();
                }
            }
            else
            {
                //если воспроизводили видео, то ставим его на паузу
                pauseVideo();
            }
            
        }
        /**
         * Проводим инициализацию после добавления на сцену
         * @param    e
         */
        private function addToStageHandler(e:Event):void 
        {
            //Удаляем обработку события добавления на сцену за ненадобностью
            removeEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
            
            //Настраиваем параметры отображения сцены
            stage.align        = StageAlign.TOP_LEFT;
            stage.scaleMode    = StageScaleMode.NO_SCALE;
            
            //VideoSim - симулирует воспроизведение видео
            someVideo = new VideoSim();
            addChild(someVideo);
            
            //Создаем кнопку управления воспроизведением
            btPlayPause        = new Bt()
            btPlayPause.y      = someVideo.height + 10;
            
            //Создаем кнопку управления звуком
            btVolume           = new Bt()
            btVolume.x         = btPlayPause.x + btPlayPause.width+10;
            btVolume.y         = btPlayPause.y;
            
            //Добавляем кнопки на сцену
            addChild(btPlayPause);
            addChild(btVolume);
            
            //Создаем клип для визуализации ресайза
            resizePoint        = new ResizePoint();
            resizePoint.x      = .5 * stage.stageWidth;
            resizePoint.y      = .5 * stage.stageHeight;
            addChild(resizePoint)
            
            //Подписываемся на события изменения размераобласти ограниченной клипом визуализации ресайза
            resizePoint.addEventListener(MouseEvent.MOUSE_DOWN, mouseResizePointHandler);
            stage.addEventListener(MouseEvent.MOUSE_UP, mouseResizePointHandler);
            
            //Для начала ставим все на паузу
            pauseVideo();
            
            //Инициализируем модуль загрузки рекламы
            adCreator = new AdCreator();
            
            //Можно посмотреть дату сборки текущего модуля
            trace("Дата сборки:", adCreator.DATE)
            
            //Подпиываемся на события загрузки и ошибки креатора
            adCreator.addEventListener(PladformAdModuleEvent.ERROR, adModuleHandler);
            adCreator.addEventListener(PladformAdModuleEvent.READY, adModuleHandler);
            
            //Загружаемся
            adCreator.load();
            
            //Подписываемся на событие клика по кнопке воспроизведения
            btPlayPause.addEventListener(MouseEvent.CLICK, playPauseClickHandler);
            
            //Подписываемся на событие клика по кнопке управления звуком
            btVolume.text = "1";
            btVolume.addEventListener(MouseEvent.CLICK, btVolumeClickHandler)
            
            //Подписываемся на окончание воспроизведения симуляции видео
            someVideo.addEventListener("videoComplete", completeVideoHandler)
            
            //подписываемся на ресайз сцены
            stage.addEventListener(Event.RESIZE, resizeHandler)
            resizeHandler(null)
        }
        
        // PRIVATE METHODS
        /**
         * Готовимся к показу преролла
         */
        private function showPreroll():void 
        {
            if (PREROLL_PATH)
            {
                //Создаем преролл - объект AdWrapper, отвечающий за показ рекламы
                adWrapperPreroll = adCreator.create();
                
                //подписываем его на все рекламные события
                initHandlers(adWrapperPreroll)
                
                //Перед загрузкой рекламы можно указать максимальное время на загрузку рекламного кода, в миллискундах (по умолчанию 3000)
                adWrapperPreroll.codeLoadTime       = 1000;
                
                //Перед загрузкой рекламы можно указать максимальное время на загрузку рекламного контента после загрузки кода, в миллискундах (по умолчанию 5000)
                adWrapperPreroll.creativeLoadTime   = 1000;
                
                //Инициируем загрузку рекламного креатива
                adWrapperPreroll.load(PREROLL_PATH);
            }
            else
            {
                //Если не указан путь то обрабатываем завершение преролла
                prerollComplete();
            }
        }
        
        /**
         * Готовимся к показу оверлея
         */
        private function showOverlay():void 
        {
            //Создаем оверлей - объект AdWrapper, отвечающий за показ рекламы
            adWrapperOverlay = adCreator.create();
            
            //подписываем его на все рекламные события
            initHandlers(adWrapperOverlay);
            
            //Инициируем загрузку рекламного креатива
            adWrapperOverlay.load(OVERLAY_PATH);
        }
        /**
         * Готовимся к показу постролла
         */
        private function showPostroll():void 
        {
            if (POSTROLL_PATH)
            {
                //Создаем постролл - объект AdWrapper, отвечающий за показ рекламы
                adWrapperPostroll = adCreator.create();
                
                //подписываем его на все рекламные события
                initHandlers(adWrapperPostroll)
                
                //Инициируем загрузку рекламного креатива
                adWrapperPostroll.load(POSTROLL_PATH);
            }
        }
        /**
         * Подписываем объект AdWrapper на все рекламные события
         * @param    adWrapper
         */
        private function initHandlers(adWrapper:AdWrapper):void
        {
            //Получаем массив всех имен событий рекламы
            var vecEvents    :Vector.<String>   = AdEvent.allEvent;
            var length        :int              = vecEvents.length
            
            //Обходим массив и подписываем AdWrapper на все события рекламы
            for (var i:int = 0; i < length; i++) 
            {
                adWrapper.addEventListener(vecEvents[i], vpaidHandler);
            }
        }
        /**
         * Воспроизведение
         */
        private function playVideo():void
        {
            //Запускаем воспроизведение
            someVideo.play();
            btPlayPause.text    = "pause";
            
            //Запускаем поиск середины видео для мидролла
            if(!isMidrollShowed && MIDROLL_PATH) addEventListener(Event.ENTER_FRAME, oefHandler)
        }
        //Пауза
        private function pauseVideo():void
        {
            //Останавливаем воспроизведение
            someVideo.stop();
            btPlayPause.text    = "play";
            
            //Отписываемся от поиска середины видео для мидролла
            if(!isMidrollShowed && MIDROLL_PATH) removeEventListener(Event.ENTER_FRAME, oefHandler)
        }
        
        private function prerollComplete():void 
        {
            //Если креатив был завершен при клике на него, то видео нужно поставить на паузу, но он и так должен быть на паузе, поэтому при нормальном завершении запускаем видео
            if (!isVideoMostStopped)    playVideo();
            isPrerollComplete    = true
            //После запуска видео начинаем обслеживать появление оверлея, в примере мы запустим таймер
            overLayTimer         = new Timer(overlayStartTime, 1);
            overLayTimer.addEventListener(TimerEvent.TIMER_COMPLETE, overLayTimerHandler);
            overLayTimer.start()
            
        }
        /**
         * обработка завершения постролла
         */
        private function postrollComplete():void 
        {
            pauseVideo();
        }
        /**
         * обработка завершения мидролла
         */
        private function modrollComplete():void 
        {
            if (!isVideoMostStopped)
            {
                playVideo();
            }
        }
        
    }

}