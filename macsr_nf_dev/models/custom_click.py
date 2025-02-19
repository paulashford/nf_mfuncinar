import click
import ast

# passing lists as string literals
# https://stackoverflow.com/questions/47631914/how-to-pass-several-list-of-arguments-to-click-option
class PythonLiteralOption(click.Option):

    def type_cast_value(self, ctx, value):
        try:
            return ast.literal_eval(value)
        except:
            raise click.BadParameter(value)
        
