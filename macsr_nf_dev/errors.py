class BaseError(BaseException):
    pass

class ParseError(BaseError):
    pass

class ArgumentError(BaseError):
    pass

class ParseMapFileError(BaseError):
    pass

class DelimeterError(BaseError):
    pass
