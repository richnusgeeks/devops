import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
    
public class TstLg4jELK {

  private static final Logger logger = Logger.getLogger(TstLg4jELK.class);

  public static void main(String argv[]) {

    PropertyConfigurator.configure("log4j.properties");
    logger.debug("ELK test 1 2 3 ...");
    logger.info("ELK test 4 5 6 ...");
  }

}

