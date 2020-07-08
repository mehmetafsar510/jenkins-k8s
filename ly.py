#  Task : Estimating the risk of death from coronavirus

age = True  # can be assigned only True/False

chronic = True # can be assigned only True/False

immune = False # can be assigned only True/False

covid_19 = age and chronic or immune

if covid_19 == True :

    print('there is a risk of death')

else :

    print('there is not a risk of death')


print(covid_19)
